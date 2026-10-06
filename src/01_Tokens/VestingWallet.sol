// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20Permit} from "./ERC20Permit.sol";

/// @title VestingWallet
/// @notice Linear and cliff-based token & native ETH vesting schedule for beneficiaries
contract VestingWallet {
    event Released(address indexed token, uint256 amount);

    error NothingToRelease();
    error TransferFailed();

    address public immutable beneficiary;
    uint64 public immutable start;
    uint64 public immutable duration;
    uint64 public immutable cliff;

    mapping(address => uint256) public released;
    uint256 public releasedETH;

    constructor(address _beneficiary, uint64 _startTimestamp, uint64 _durationSeconds, uint64 _cliffSeconds) {
        require(_beneficiary != address(0), "Zero address beneficiary");
        require(_durationSeconds > 0, "Zero duration");
        require(_cliffSeconds <= _durationSeconds, "Cliff exceeds duration");

        beneficiary = _beneficiary;
        start = _startTimestamp;
        duration = _durationSeconds;
        cliff = _startTimestamp + _cliffSeconds;
    }

    receive() external payable {}

    function releaseETH() public {
        uint256 releasable = vestedAmountETH(uint64(block.timestamp)) - releasedETH;
        if (releasable == 0) revert NothingToRelease();

        releasedETH += releasable;
        (bool success,) = beneficiary.call{value: releasable}("");
        if (!success) revert TransferFailed();

        emit Released(address(0), releasable);
    }

    function release(address token) public {
        uint256 releasable = vestedAmount(token, uint64(block.timestamp)) - released[token];
        if (releasable == 0) revert NothingToRelease();

        released[token] += releasable;
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(ERC20Permit.transfer.selector, beneficiary, releasable));
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) revert TransferFailed();

        emit Released(token, releasable);
    }

    function vestedAmountETH(uint64 timestamp) public view returns (uint256) {
        uint256 totalAllocation = address(this).balance + releasedETH;
        return _vestingSchedule(totalAllocation, timestamp);
    }

    function vestedAmount(address token, uint64 timestamp) public view returns (uint256) {
        (bool success, bytes memory data) =
            token.staticcall(abi.encodeWithSignature("balanceOf(address)", address(this)));
        require(success && data.length >= 32, "balanceOf failed");
        uint256 balance = abi.decode(data, (uint256));

        uint256 totalAllocation = balance + released[token];
        return _vestingSchedule(totalAllocation, timestamp);
    }

    function _vestingSchedule(uint256 totalAllocation, uint64 timestamp) internal view returns (uint256) {
        if (timestamp < cliff) {
            return 0;
        } else if (timestamp >= start + duration) {
            return totalAllocation;
        } else {
            return (totalAllocation * (timestamp - start)) / duration;
        }
    }
}
