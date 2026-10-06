// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title SocialRecoveryWallet
/// @notice Smart contract wallet with guardian-based key recovery and security timelock.
contract SocialRecoveryWallet {
    // --- Errors ---
    error NotOwner();
    error NotGuardian();
    error InvalidGuardians();
    error RecoveryAlreadyActive();
    error NoActiveRecovery();
    error AlreadyVoted();
    error ThresholdNotMet();
    error TimelockPending();
    error ExecutionFailed();
    error ZeroAddress();

    // --- Events ---
    event Executed(address indexed to, uint256 value, bytes data);
    event RecoveryInitiated(address indexed proposedOwner, uint256 executeAfter);
    event RecoverySupported(address indexed guardian, address indexed proposedOwner, uint256 voteCount);
    event RecoveryCancelled();
    event RecoveryCompleted(address indexed previousOwner, address indexed newOwner);

    // --- State Variables ---
    address public owner;
    uint256 public immutable guardianThreshold;
    uint256 public immutable recoveryDelay;

    mapping(address => bool) public isGuardian;
    address[] public guardians;

    struct Recovery {
        address proposedOwner;
        uint256 votes;
        uint256 executeAfter;
        bool active;
    }

    Recovery public activeRecovery;
    mapping(address => bool) public hasVoted;

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier onlyGuardian() {
        if (!isGuardian[msg.sender]) revert NotGuardian();
        _;
    }

    constructor(address _owner, address[] memory _guardians, uint256 _threshold, uint256 _recoveryDelay) {
        if (_owner == address(0)) revert ZeroAddress();
        if (_threshold == 0 || _threshold > _guardians.length) revert InvalidGuardians();

        owner = _owner;
        guardianThreshold = _threshold;
        recoveryDelay = _recoveryDelay;

        for (uint256 i = 0; i < _guardians.length; i++) {
            address g = _guardians[i];
            if (g == address(0) || isGuardian[g]) revert InvalidGuardians();
            isGuardian[g] = true;
            guardians.push(g);
        }
    }

    receive() external payable {}

    function execute(address to, uint256 value, bytes calldata data) external onlyOwner returns (bytes memory result) {
        bool success;
        (success, result) = to.call{value: value}(data);
        if (!success) revert ExecutionFailed();

        emit Executed(to, value, data);
    }

    /// @notice Guardian initiates recovery of account ownership
    function initiateRecovery(address newOwner) external onlyGuardian {
        if (newOwner == address(0)) revert ZeroAddress();
        if (activeRecovery.active) revert RecoveryAlreadyActive();

        activeRecovery =
            Recovery({proposedOwner: newOwner, votes: 1, executeAfter: block.timestamp + recoveryDelay, active: true});

        hasVoted[msg.sender] = true;

        emit RecoveryInitiated(newOwner, activeRecovery.executeAfter);
        emit RecoverySupported(msg.sender, newOwner, 1);
    }

    /// @notice Guardian votes to support the active recovery proposal
    function supportRecovery(address proposedOwner) external onlyGuardian {
        if (!activeRecovery.active || activeRecovery.proposedOwner != proposedOwner) {
            revert NoActiveRecovery();
        }
        if (hasVoted[msg.sender]) revert AlreadyVoted();

        hasVoted[msg.sender] = true;
        activeRecovery.votes += 1;

        emit RecoverySupported(msg.sender, proposedOwner, activeRecovery.votes);
    }

    /// @notice Owner can cancel any recovery attempt
    function cancelRecovery() external onlyOwner {
        if (!activeRecovery.active) revert NoActiveRecovery();
        _resetRecovery();
        emit RecoveryCancelled();
    }

    /// @notice Finalize ownership handover once threshold and delay are satisfied
    function executeRecovery() external {
        if (!activeRecovery.active) revert NoActiveRecovery();
        if (activeRecovery.votes < guardianThreshold) revert ThresholdNotMet();
        if (block.timestamp < activeRecovery.executeAfter) revert TimelockPending();

        address previousOwner = owner;
        owner = activeRecovery.proposedOwner;

        _resetRecovery();

        emit RecoveryCompleted(previousOwner, owner);
    }

    function _resetRecovery() internal {
        for (uint256 i = 0; i < guardians.length; i++) {
            hasVoted[guardians[i]] = false;
        }
        delete activeRecovery;
    }
}
