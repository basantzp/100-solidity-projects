// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title SoftLiquidationProtector
/// @notice Curve LLAMMA-inspired automated soft liquidation and health-factor rebalancing keeper.
contract SoftLiquidationProtector {
    // --- Errors ---
    error PositionHealthy();
    error TransferFailed();
    error ZeroAmount();

    // --- Events ---
    event Rebalanced(address indexed user, uint256 collateralSold, uint256 debtRepaid, uint256 newHealthFactor);

    struct UserPosition {
        uint256 collateral;
        uint256 debt;
    }

    address public immutable collateralToken;
    address public immutable debtToken;

    // Thresholds in basis points
    uint256 public constant SOFT_LIQUIDATION_THRESHOLD = 11500; // 1.15x health factor (115%)
    uint256 public constant TARGET_HEALTH_FACTOR = 13000; // 1.30x target health factor

    mapping(address => UserPosition) public positions;

    constructor(address _collateralToken, address _debtToken) {
        collateralToken = _collateralToken;
        debtToken = _debtToken;
    }

    function setPosition(address user, uint256 col, uint256 debt) external {
        positions[user] = UserPosition({collateral: col, debt: debt});
    }

    /// @notice Calculates position health factor given current oracle price of collateral
    /// @param priceUSD Price of 1 unit of collateral in USD (18 decimals)
    function getHealthFactor(address user, uint256 priceUSD) public view returns (uint256 healthBps) {
        UserPosition storage pos = positions[user];
        if (pos.debt == 0) return type(uint256).max;

        uint256 colValue = (pos.collateral * priceUSD) / 1e18;
        return (colValue * 10_000) / pos.debt;
    }

    /// @notice Keeper triggers soft liquidation to rebalance position if health factor drops below 1.15
    function rebalance(address user, uint256 priceUSD) external returns (uint256 colSold, uint256 debtRepaid) {
        uint256 currentHealth = getHealthFactor(user, priceUSD);
        if (currentHealth >= SOFT_LIQUIDATION_THRESHOLD) revert PositionHealthy();

        UserPosition storage pos = positions[user];

        // Sell 20% of collateral to repay debt
        colSold = pos.collateral / 5;
        debtRepaid = (colSold * priceUSD) / 1e18;
        if (debtRepaid > pos.debt) debtRepaid = pos.debt;

        pos.collateral -= colSold;
        pos.debt -= debtRepaid;

        uint256 newHealth = getHealthFactor(user, priceUSD);
        emit Rebalanced(user, colSold, debtRepaid, newHealth);
    }
}
