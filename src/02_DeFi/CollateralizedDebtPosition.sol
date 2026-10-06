// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title CollateralizedDebtPosition (CDP)
/// @notice MakerDAO-style overcollateralized stablecoin borrowing and liquidation vault.
contract CollateralizedDebtPosition {
    // --- Errors ---
    error ZeroAmount();
    error UnsafeCollateralRatio();
    error NotLiquidatable();
    error ExceedsCollateral();
    error TransferFailed();

    // --- Structs ---
    struct Position {
        uint256 collateralETH;
        uint256 debt; // Scaled by 1e18
    }

    // --- State Variables ---
    address public immutable debtToken;
    uint256 public ethPriceUSD; // ETH price in USD, scaled by 1e18 (e.g. 2000e18)
    uint256 public constant MIN_COLLATERAL_RATIO = 150; // 150% min ratio to borrow
    uint256 public constant LIQUIDATION_THRESHOLD = 130; // 130% liquidation trigger
    uint256 public constant LIQUIDATION_BONUS = 110; // 10% discount on seized collateral for liquidator

    mapping(address => Position) public positions;

    event CollateralDeposited(address indexed user, uint256 amount);
    event CollateralWithdrawn(address indexed user, uint256 amount);
    event DebtMinted(address indexed user, uint256 amount);
    event DebtRepaid(address indexed user, uint256 amount);
    event Liquidated(address indexed user, address indexed liquidator, uint256 debtRepaid, uint256 collateralSeized);

    constructor(address _debtToken, uint256 _initialEthPriceUSD) {
        debtToken = _debtToken;
        ethPriceUSD = _initialEthPriceUSD;
    }

    function setEthPriceUSD(uint256 newPrice) external {
        ethPriceUSD = newPrice;
    }

    /// @notice Deposit native ETH as collateral
    function depositCollateral() external payable {
        if (msg.value == 0) revert ZeroAmount();
        positions[msg.sender].collateralETH += msg.value;
        emit CollateralDeposited(msg.sender, msg.value);
    }

    /// @notice Mint debt stablecoins against deposited collateral
    function borrow(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();
        Position storage pos = positions[msg.sender];
        pos.debt += amount;

        if (getHealthRatio(msg.sender) < MIN_COLLATERAL_RATIO) {
            revert UnsafeCollateralRatio();
        }

        _mintDebtToken(msg.sender, amount);
        emit DebtMinted(msg.sender, amount);
    }

    /// @notice Repay minted debt tokens
    function repay(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();
        Position storage pos = positions[msg.sender];
        if (amount > pos.debt) amount = pos.debt;

        pos.debt -= amount;
        _burnDebtToken(msg.sender, amount);

        emit DebtRepaid(msg.sender, amount);
    }

    /// @notice Withdraw collateral as long as health ratio remains >= 150%
    function withdrawCollateral(uint256 amount) external {
        Position storage pos = positions[msg.sender];
        if (amount > pos.collateralETH) revert ExceedsCollateral();

        pos.collateralETH -= amount;
        if (pos.debt > 0 && getHealthRatio(msg.sender) < MIN_COLLATERAL_RATIO) {
            revert UnsafeCollateralRatio();
        }

        (bool success,) = msg.sender.call{value: amount}("");
        if (!success) revert TransferFailed();

        emit CollateralWithdrawn(msg.sender, amount);
    }

    /// @notice Liquidate undercollateralized position
    function liquidate(address user) external {
        Position storage pos = positions[user];
        if (getHealthRatio(user) >= LIQUIDATION_THRESHOLD) revert NotLiquidatable();

        uint256 userDebt = pos.debt;
        uint256 userCollateral = pos.collateralETH;

        // Collateral value to seize: debt * LIQUIDATION_BONUS / ethPriceUSD
        uint256 collateralToSeize = (userDebt * LIQUIDATION_BONUS * 1e18) / (ethPriceUSD * 100);
        if (collateralToSeize > userCollateral) {
            collateralToSeize = userCollateral;
        }

        pos.debt = 0;
        pos.collateralETH -= collateralToSeize;

        // Burn liquidator's debt tokens
        _burnDebtToken(msg.sender, userDebt);

        // Send seized collateral to liquidator
        (bool success,) = msg.sender.call{value: collateralToSeize}("");
        if (!success) revert TransferFailed();

        emit Liquidated(user, msg.sender, userDebt, collateralToSeize);
    }

    /// @notice Collateral ratio as percentage (e.g. 150 = 150%)
    function getHealthRatio(address user) public view returns (uint256) {
        Position storage pos = positions[user];
        if (pos.debt == 0) return type(uint256).max;

        uint256 collateralValueUSD = (pos.collateralETH * ethPriceUSD) / 1e18;
        return (collateralValueUSD * 100) / pos.debt;
    }

    function _mintDebtToken(address to, uint256 amount) internal {
        (bool success,) = debtToken.call(abi.encodeWithSignature("mint(address,uint256)", to, amount));
        if (!success) revert TransferFailed();
    }

    function _burnDebtToken(address from, uint256 amount) internal {
        (bool success,) = debtToken.call(abi.encodeWithSignature("burn(address,uint256)", from, amount));
        if (!success) revert TransferFailed();
    }
}
