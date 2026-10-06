// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title SpendingLimitAccount
/// @notice Treasury smart account enforcing rolling 24-hour withdrawal quotas for operators.
contract SpendingLimitAccount {
    // --- Errors ---
    error ExceedsSpendingLimit(uint256 requested, uint256 remaining);
    error Unauthorized();
    error TransferFailed();
    error ZeroAddress();

    // --- Events ---
    event SpendingLimitUpdated(uint256 newLimit);
    event SpenderAuthorizationChanged(address indexed spender, bool authorized);
    event FundsWithdrawn(address indexed spender, address indexed to, uint256 amount);

    // --- State Variables ---
    address public owner;
    uint256 public dailyLimit;
    uint256 public spentToday;
    uint256 public currentDay;

    mapping(address => bool) public isAuthorizedSpender;

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    modifier onlyAuthorized() {
        if (msg.sender != owner && !isAuthorizedSpender[msg.sender]) revert Unauthorized();
        _;
    }

    constructor(uint256 _dailyLimit) {
        owner = msg.sender;
        dailyLimit = _dailyLimit;
        currentDay = block.timestamp / 1 days;
    }

    receive() external payable {}

    function setDailyLimit(uint256 _newLimit) external onlyOwner {
        dailyLimit = _newLimit;
        emit SpendingLimitUpdated(_newLimit);
    }

    function setSpenderAuthorization(address spender, bool authorized) external onlyOwner {
        if (spender == address(0)) revert ZeroAddress();
        isAuthorizedSpender[spender] = authorized;
        emit SpenderAuthorizationChanged(spender, authorized);
    }

    /// @notice Withdraw native ETH within authorized quota limits
    function withdraw(address payable to, uint256 amount) external onlyAuthorized {
        if (to == address(0)) revert ZeroAddress();

        if (msg.sender != owner) {
            uint256 today = block.timestamp / 1 days;
            if (today > currentDay) {
                currentDay = today;
                spentToday = 0;
            }

            uint256 remaining = dailyLimit > spentToday ? dailyLimit - spentToday : 0;
            if (amount > remaining) {
                revert ExceedsSpendingLimit(amount, remaining);
            }

            spentToday += amount;
        }

        (bool success,) = to.call{value: amount}("");
        if (!success) revert TransferFailed();

        emit FundsWithdrawn(msg.sender, to, amount);
    }

    function remainingDailyLimit() external view returns (uint256) {
        uint256 today = block.timestamp / 1 days;
        if (today > currentDay) {
            return dailyLimit;
        }
        return dailyLimit > spentToday ? dailyLimit - spentToday : 0;
    }
}
