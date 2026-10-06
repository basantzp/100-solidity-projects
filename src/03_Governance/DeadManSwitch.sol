// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title DeadManSwitch
/// @notice Heartbeat-dependent cryptocurrency inheritance mechanism.
/// @dev If owner misses regular heartbeat pings beyond the timeout threshold, beneficiary can claim assets.
contract DeadManSwitch {
    // --- Errors ---
    error OwnerStillAlive(uint256 remainingTime);
    error Unauthorized();
    error TransferFailed();
    error ZeroAddress();
    error InvalidTimeout();

    // --- Events ---
    event HeartbeatPinged(uint256 timestamp);
    event BeneficiaryChanged(address indexed previousBeneficiary, address indexed newBeneficiary);
    event TimeoutIntervalChanged(uint256 newInterval);
    event InheritanceClaimed(address indexed beneficiary, uint256 amount);

    // --- State Variables ---
    address public owner;
    address public beneficiary;
    uint256 public timeoutInterval;
    uint256 public lastHeartbeat;

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    constructor(address _beneficiary, uint256 _timeoutInterval) payable {
        if (_beneficiary == address(0)) revert ZeroAddress();
        if (_timeoutInterval == 0) revert InvalidTimeout();

        owner = msg.sender;
        beneficiary = _beneficiary;
        timeoutInterval = _timeoutInterval;
        lastHeartbeat = block.timestamp;
    }

    receive() external payable {}

    /// @notice Owner checks in to prove liveness and reset countdown timer
    function ping() external onlyOwner {
        lastHeartbeat = block.timestamp;
        emit HeartbeatPinged(block.timestamp);
    }

    function setBeneficiary(address newBeneficiary) external onlyOwner {
        if (newBeneficiary == address(0)) revert ZeroAddress();
        emit BeneficiaryChanged(beneficiary, newBeneficiary);
        beneficiary = newBeneficiary;
    }

    function setTimeoutInterval(uint256 newInterval) external onlyOwner {
        if (newInterval == 0) revert InvalidTimeout();
        timeoutInterval = newInterval;
        emit TimeoutIntervalChanged(newInterval);
    }

    /// @notice Check if the dead man's switch has tripped
    function isTriggered() public view returns (bool) {
        return block.timestamp > lastHeartbeat + timeoutInterval;
    }

    /// @notice Beneficiary claims all held funds once switch has triggered
    function claimInheritance() external {
        if (msg.sender != beneficiary) revert Unauthorized();
        if (!isTriggered()) {
            uint256 remaining = (lastHeartbeat + timeoutInterval) - block.timestamp;
            revert OwnerStillAlive(remaining);
        }

        uint256 balance = address(this).balance;
        (bool success,) = payable(beneficiary).call{value: balance}("");
        if (!success) revert TransferFailed();

        emit InheritanceClaimed(beneficiary, balance);
    }
}
