// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title VariableRateMarket
/// @notice Kinked-curve utilization-based interest rate money market primitive (Aave/Compound model).
contract VariableRateMarket {
    // --- Errors ---
    error ZeroAmount();
    error InsufficientLiquidity();
    error TransferFailed();

    // --- Rate Model Parameters (scaled by 1e18) ---
    uint256 public constant BASE_RATE = 0.02e18; // 2% base rate
    uint256 public constant OPTIMAL_UTILIZATION = 0.8e18; // 80% kink point
    uint256 public constant SLOPE_1 = 0.04e18; // 4% slope below kink
    uint256 public constant SLOPE_2 = 0.75e18; // 75% slope above kink (steep penalty)
    uint256 public constant SECONDS_PER_YEAR = 31536000;

    // --- State Variables ---
    address public immutable asset;
    uint256 public totalDeposits;
    uint256 public totalBorrows;

    uint256 public borrowIndex;
    uint256 public lastAccrualTimestamp;

    mapping(address => uint256) public depositBalance;
    mapping(address => uint256) public userBorrowShares;

    event Deposited(address indexed user, uint256 amount);
    event Borrowed(address indexed user, uint256 amount);
    event Repaid(address indexed user, uint256 amount);

    constructor(address _asset) {
        asset = _asset;
        borrowIndex = 1e18;
        lastAccrualTimestamp = block.timestamp;
    }

    /// @notice Accrue interest based on elapsed time and current borrow rate
    function accrueInterest() public {
        uint256 elapsed = block.timestamp - lastAccrualTimestamp;
        if (elapsed == 0) return;

        uint256 rate = getBorrowRate();
        uint256 interestFactor = (rate * elapsed) / SECONDS_PER_YEAR;

        // Compound borrow index
        borrowIndex += (borrowIndex * interestFactor) / 1e18;

        // Interest adds to total borrows
        uint256 interestAccrued = (totalBorrows * interestFactor) / 1e18;
        totalBorrows += interestAccrued;
        totalDeposits += interestAccrued; // Simplified: 0% reserve factor

        lastAccrualTimestamp = block.timestamp;
    }

    /// @notice Get current annual borrow rate based on utilization kink
    function getBorrowRate() public view returns (uint256) {
        if (totalDeposits == 0) return BASE_RATE;

        uint256 utilization = (totalBorrows * 1e18) / totalDeposits;
        if (utilization <= OPTIMAL_UTILIZATION) {
            return BASE_RATE + (utilization * SLOPE_1) / OPTIMAL_UTILIZATION;
        } else {
            uint256 excessUtilization = utilization - OPTIMAL_UTILIZATION;
            uint256 excessCoverage = 1e18 - OPTIMAL_UTILIZATION;
            return BASE_RATE + SLOPE_1 + (excessUtilization * SLOPE_2) / excessCoverage;
        }
    }

    function deposit(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();
        accrueInterest();

        totalDeposits += amount;
        depositBalance[msg.sender] += amount;

        _safeTransferFrom(asset, msg.sender, address(this), amount);
        emit Deposited(msg.sender, amount);
    }

    function borrow(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();
        accrueInterest();

        uint256 available = totalDeposits - totalBorrows;
        if (amount > available) revert InsufficientLiquidity();

        uint256 shares = (amount * 1e18) / borrowIndex;
        userBorrowShares[msg.sender] += shares;
        totalBorrows += amount;

        _safeTransfer(asset, msg.sender, amount);
        emit Borrowed(msg.sender, amount);
    }

    function repay(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();
        accrueInterest();

        uint256 userDebt = (userBorrowShares[msg.sender] * borrowIndex) / 1e18;
        if (amount > userDebt) amount = userDebt;

        uint256 sharesRepaid = (amount * 1e18) / borrowIndex;
        userBorrowShares[msg.sender] -= sharesRepaid;
        totalBorrows -= amount;

        _safeTransferFrom(asset, msg.sender, address(this), amount);
        emit Repaid(msg.sender, amount);
    }

    function getUserDebt(address user) external view returns (uint256) {
        return (userBorrowShares[user] * borrowIndex) / 1e18;
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
