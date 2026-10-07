// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title CrossCollateralBasket
/// @notice Multi-collateral margin basket allowing unified borrowing power across distinct collateral assets.
contract CrossCollateralBasket {
    // --- Errors ---
    error UnsupportedToken();
    error ExceedsBorrowingPower();
    error InsufficientCollateral();
    error TransferFailed();
    error ZeroAmount();
    error Unauthorized();

    // --- Events ---
    event CollateralDeposited(address indexed user, address indexed token, uint256 amount);
    event CollateralWithdrawn(address indexed user, address indexed token, uint256 amount);
    event Borrowed(address indexed user, uint256 amount);
    event Repaid(address indexed user, uint256 amount);

    struct TokenConfig {
        bool isSupported;
        uint256 ltvBps; // Loan-To-Value in basis points (e.g., 7500 = 75%)
        uint256 priceUSD; // Normalized price in 18 decimals
    }

    address public immutable owner;
    address public immutable debtToken;

    mapping(address => TokenConfig) public tokenConfigs;
    address[] public supportedTokens;

    // user => token => balance
    mapping(address => mapping(address => uint256)) public userCollateral;
    // user => debt
    mapping(address => uint256) public userDebt;

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    constructor(address _debtToken) {
        owner = msg.sender;
        debtToken = _debtToken;
    }

    function addSupportedToken(address token, uint256 ltvBps, uint256 priceUSD) external onlyOwner {
        tokenConfigs[token] = TokenConfig({isSupported: true, ltvBps: ltvBps, priceUSD: priceUSD});
        supportedTokens.push(token);
    }

    function setTokenPrice(address token, uint256 newPriceUSD) external onlyOwner {
        if (!tokenConfigs[token].isSupported) revert UnsupportedToken();
        tokenConfigs[token].priceUSD = newPriceUSD;
    }

    function depositCollateral(address token, uint256 amount) external {
        if (!tokenConfigs[token].isSupported) revert UnsupportedToken();
        if (amount == 0) revert ZeroAmount();

        userCollateral[msg.sender][token] += amount;
        _safeTransferFrom(token, msg.sender, address(this), amount);

        emit CollateralDeposited(msg.sender, token, amount);
    }

    /// @notice Calculates total borrowing power in USD for an account
    function calculateBorrowingPower(address user) public view returns (uint256 totalPowerUSD) {
        for (uint256 i = 0; i < supportedTokens.length; i++) {
            address t = supportedTokens[i];
            uint256 bal = userCollateral[user][t];
            if (bal > 0) {
                TokenConfig memory cfg = tokenConfigs[t];
                // valueUSD = (bal * priceUSD) / 1e18
                // powerUSD = (valueUSD * ltvBps) / 10_000
                uint256 valueUSD = (bal * cfg.priceUSD) / 1e18;
                totalPowerUSD += (valueUSD * cfg.ltvBps) / 10_000;
            }
        }
    }

    function borrow(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();

        uint256 power = calculateBorrowingPower(msg.sender);
        uint256 newDebt = userDebt[msg.sender] + amount;

        if (newDebt > power) revert ExceedsBorrowingPower();

        userDebt[msg.sender] = newDebt;
        _safeTransfer(debtToken, msg.sender, amount);

        emit Borrowed(msg.sender, amount);
    }

    function repay(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();

        uint256 currentDebt = userDebt[msg.sender];
        uint256 repayAmount = amount > currentDebt ? currentDebt : amount;

        userDebt[msg.sender] -= repayAmount;
        _safeTransferFrom(debtToken, msg.sender, address(this), repayAmount);

        emit Repaid(msg.sender, repayAmount);
    }

    function withdrawCollateral(address token, uint256 amount) external {
        if (amount == 0) revert ZeroAmount();
        if (userCollateral[msg.sender][token] < amount) revert InsufficientCollateral();

        userCollateral[msg.sender][token] -= amount;

        // Ensure remaining collateral covers existing debt
        uint256 remainingPower = calculateBorrowingPower(msg.sender);
        if (userDebt[msg.sender] > remainingPower) revert ExceedsBorrowingPower();

        _safeTransfer(token, msg.sender, amount);
        emit CollateralWithdrawn(msg.sender, token, amount);
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
