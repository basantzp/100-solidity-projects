// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title BlacklistGate
/// @notice Compliance and sanctions enforcement gate that blocks malicious or flagged addresses.
contract BlacklistGate {
    // --- Errors ---
    error AccountBlacklisted(address account);
    error Unauthorized();
    error ZeroAddress();

    // --- Events ---
    event BlacklistUpdated(address indexed account, bool isBlacklisted);

    // --- State Variables ---
    address public complianceOfficer;
    mapping(address => bool) public isBlacklisted;

    modifier notBlacklisted(address account) {
        if (isBlacklisted[account]) revert AccountBlacklisted(account);
        _;
    }

    modifier onlyOfficer() {
        if (msg.sender != complianceOfficer) revert Unauthorized();
        _;
    }

    constructor() {
        complianceOfficer = msg.sender;
    }

    function setBlacklisted(address account, bool status) external onlyOfficer {
        if (account == address(0)) revert ZeroAddress();
        isBlacklisted[account] = status;
        emit BlacklistUpdated(account, status);
    }

    function transferComplianceOfficer(address newOfficer) external onlyOfficer {
        if (newOfficer == address(0)) revert ZeroAddress();
        complianceOfficer = newOfficer;
    }
}
