// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title SpendingGuardianHook
/// @notice ERC-7579 pre-execution policy hook enforcing 24h rolling velocity limits and target whitelisting.
contract SpendingGuardianHook {
    // --- Errors ---
    error DailySpendingLimitExceeded();
    error TargetNotWhitelisted();
    error Unauthorized();

    // --- Events ---
    event SpendingLimitSet(address indexed account, uint256 maxDailyLimit);
    event TargetWhitelisted(address indexed account, address indexed target, bool allowed);

    struct DailyLimit {
        uint256 maxLimit;
        uint256 currentSpent;
        uint256 windowStart;
    }

    mapping(address => DailyLimit) public limits;
    // account => target => isWhitelisted
    mapping(address => mapping(address => bool)) public whitelistedTargets;

    function setDailyLimit(uint256 maxLimit) external {
        limits[msg.sender].maxLimit = maxLimit;
        emit SpendingLimitSet(msg.sender, maxLimit);
    }

    function setTargetWhitelisted(address target, bool allowed) external {
        whitelistedTargets[msg.sender][target] = allowed;
        emit TargetWhitelisted(msg.sender, target, allowed);
    }

    /// @notice Hook called before smart account executes transaction
    function preCheckExecution(address account, address target, uint256 value) external {
        DailyLimit storage dl = limits[account];

        // Check target whitelist if whitelist configured
        if (!whitelistedTargets[account][target]) {
            revert TargetNotWhitelisted();
        }

        // Check velocity limit
        if (dl.maxLimit > 0) {
            if (block.timestamp >= dl.windowStart + 1 days) {
                dl.windowStart = block.timestamp;
                dl.currentSpent = 0;
            }

            if (dl.currentSpent + value > dl.maxLimit) {
                revert DailySpendingLimitExceeded();
            }

            dl.currentSpent += value;
        }
    }
}
