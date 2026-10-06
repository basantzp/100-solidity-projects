// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title EmergencyPausable
/// @notice Circuit breaker pause mechanism to halt state-changing operations during incidents.
contract EmergencyPausable {
    // --- Errors ---
    error EnforcedPause();
    error ExpectedPause();
    error UnauthorizedPauser();

    // --- Events ---
    event Paused(address indexed account);
    event Unpaused(address indexed account);

    // --- State Variables ---
    bool public paused;
    address public pauser;

    modifier whenNotPaused() {
        if (paused) revert EnforcedPause();
        _;
    }

    modifier whenPaused() {
        if (!paused) revert ExpectedPause();
        _;
    }

    modifier onlyPauser() {
        if (msg.sender != pauser) revert UnauthorizedPauser();
        _;
    }

    constructor() {
        pauser = msg.sender;
    }

    function pause() external onlyPauser whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyPauser whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    function setPauser(address newPauser) external onlyPauser {
        if (newPauser == address(0)) revert UnauthorizedPauser();
        pauser = newPauser;
    }
}
