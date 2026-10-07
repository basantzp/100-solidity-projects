// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title RecoveryModule
/// @notice Social recovery plugin for smart accounts with guardian voting and security timelock.
contract RecoveryModule {
    // --- Errors ---
    error NotAGuardian();
    error RecoveryAlreadyActive();
    error RecoveryNotDue();
    error AlreadyConfirmed();
    error ThresholdNotMet();
    error Unauthorized();

    // --- Events ---
    event RecoveryInitiated(address indexed account, address indexed newOwner, uint256 executeAfter);
    event RecoveryConfirmed(address indexed account, address indexed guardian);
    event RecoveryExecuted(address indexed account, address indexed newOwner);
    event RecoveryCancelled(address indexed account);

    struct RecoveryRequest {
        address newOwner;
        uint256 executeAfter;
        uint256 confirmations;
        bool active;
    }

    // account => guardian => isGuardian
    mapping(address => mapping(address => bool)) public isGuardian;
    // account => guardianCount
    mapping(address => uint256) public guardianThreshold;

    // account => recovery
    mapping(address => RecoveryRequest) public recoveries;
    // account => guardian => hasConfirmed
    mapping(address => mapping(address => bool)) public hasConfirmed;

    uint256 public constant RECOVERY_TIMELOCK = 1 days;

    function setupGuardians(address[] calldata guardians, uint256 threshold) external {
        for (uint256 i = 0; i < guardians.length; i++) {
            isGuardian[msg.sender][guardians[i]] = true;
        }
        guardianThreshold[msg.sender] = threshold;
    }

    function initiateRecovery(address account, address newOwner) external {
        if (!isGuardian[account][msg.sender]) revert NotAGuardian();
        if (recoveries[account].active) revert RecoveryAlreadyActive();

        recoveries[account] = RecoveryRequest({
            newOwner: newOwner, executeAfter: block.timestamp + RECOVERY_TIMELOCK, confirmations: 1, active: true
        });

        hasConfirmed[account][msg.sender] = true;
        emit RecoveryInitiated(account, newOwner, block.timestamp + RECOVERY_TIMELOCK);
    }

    function confirmRecovery(address account) external {
        if (!isGuardian[account][msg.sender]) revert NotAGuardian();
        if (!recoveries[account].active) revert RecoveryNotDue();
        if (hasConfirmed[account][msg.sender]) revert AlreadyConfirmed();

        hasConfirmed[account][msg.sender] = true;
        recoveries[account].confirmations++;

        emit RecoveryConfirmed(account, msg.sender);
    }

    function executeRecovery(address account) external returns (address newOwner) {
        RecoveryRequest storage req = recoveries[account];
        if (!req.active) revert RecoveryNotDue();
        if (req.confirmations < guardianThreshold[account]) revert ThresholdNotMet();
        if (block.timestamp < req.executeAfter) revert RecoveryNotDue();

        newOwner = req.newOwner;
        delete recoveries[account];

        emit RecoveryExecuted(account, newOwner);
    }

    function cancelRecovery() external {
        delete recoveries[msg.sender];
        emit RecoveryCancelled(msg.sender);
    }
}
