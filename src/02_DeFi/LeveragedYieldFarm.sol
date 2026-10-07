// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title LeveragedYieldFarm
/// @notice Flash-borrow boosted yield farming position manager with leverage up to 3x.
contract LeveragedYieldFarm {
    // --- Errors ---
    error InvalidLeverage();
    error PositionUnhealthy();
    error InsufficientCollateral();
    error Unauthorized();
    error TransferFailed();
    error ZeroAmount();

    // --- Events ---
    event PositionOpened(address indexed user, uint256 collateral, uint256 borrowed, uint256 totalFarmed);
    event PositionClosed(address indexed user, uint256 returnedPrincipal, uint256 debtRepaid, uint256 yieldHarvested);
    event FarmLiquidated(address indexed user, address indexed liquidator, uint256 collateralSeized);

    struct Position {
        uint256 collateralAmount;
        uint256 borrowedAmount;
        uint256 farmShares;
        uint256 openTimestamp;
    }

    address public immutable asset;
    uint256 public constant MAX_LEVERAGE = 3; // 3x
    uint256 public constant LIQUIDATION_THRESHOLD_BPS = 8000; // 80% LTV
    uint256 public constant YIELD_APR_BPS = 1200; // 12% simulated APR

    mapping(address => Position) public positions;

    constructor(address _asset) {
        asset = _asset;
    }

    /// @notice Opens leveraged position: deposits collateral and borrows asset up to leverage factor
    function openPosition(uint256 collateral, uint256 leverageFactor) external {
        if (collateral == 0) revert ZeroAmount();
        if (leverageFactor < 1 || leverageFactor > MAX_LEVERAGE) revert InvalidLeverage();

        uint256 borrowed = collateral * (leverageFactor - 1);
        uint256 totalFarmed = collateral + borrowed;

        Position storage pos = positions[msg.sender];
        pos.collateralAmount += collateral;
        pos.borrowedAmount += borrowed;
        pos.farmShares += totalFarmed;
        pos.openTimestamp = block.timestamp;

        _safeTransferFrom(asset, msg.sender, address(this), collateral);

        emit PositionOpened(msg.sender, collateral, borrowed, totalFarmed);
    }

    /// @notice Calculates accumulated yield based on time elapsed and farming shares
    function getPendingYield(address user) public view returns (uint256) {
        Position storage pos = positions[user];
        if (pos.farmShares == 0) return 0;

        uint256 elapsed = block.timestamp - pos.openTimestamp;
        return (pos.farmShares * YIELD_APR_BPS * elapsed) / (10_000 * 365 days);
    }

    /// @notice Closes user's position, repays debt, and returns collateral + yield
    function closePosition() external returns (uint256 payout) {
        Position storage pos = positions[msg.sender];
        if (pos.farmShares == 0) revert InsufficientCollateral();

        uint256 accruedYield = getPendingYield(msg.sender);
        uint256 totalPool = pos.farmShares + accruedYield;
        uint256 debt = pos.borrowedAmount;

        if (totalPool < debt) revert PositionUnhealthy();

        payout = totalPool - debt;
        uint256 repaid = debt;
        uint256 harvested = accruedYield;

        delete positions[msg.sender];

        _safeTransfer(asset, msg.sender, payout);

        emit PositionClosed(msg.sender, payout, repaid, harvested);
    }

    /// @notice Liquidates an underwater position when health drops
    function liquidate(address borrower) external {
        Position storage pos = positions[borrower];
        if (pos.farmShares == 0) revert InsufficientCollateral();

        uint256 totalValue = pos.farmShares;
        // If borrowed / totalValue > 80%, liquidate
        if ((pos.borrowedAmount * 10_000) / totalValue < LIQUIDATION_THRESHOLD_BPS) {
            revert PositionUnhealthy();
        }

        uint256 seized = pos.farmShares;
        delete positions[borrower];

        _safeTransfer(asset, msg.sender, seized);
        emit FarmLiquidated(borrower, msg.sender, seized);
    }

    function _safeTransfer(address token, address to, uint256 amount) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSignature("transfer(address,uint256)", to, amount));
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) revert TransferFailed();
    }

    function _safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, amount));
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) revert TransferFailed();
    }
}
