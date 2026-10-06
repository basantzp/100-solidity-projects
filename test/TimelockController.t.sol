// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {TimelockController} from "../src/03_Governance/TimelockController.sol";

contract TargetMock {
    uint256 public value;

    function setValue(uint256 _value) external payable {
        value = _value;
    }
}

contract TimelockControllerTest is Test {
    TimelockController timelock;
    TargetMock target;

    uint256 minDelay = 2 days;

    function setUp() public {
        timelock = new TimelockController(minDelay);
        target = new TargetMock();
    }

    function test_QueueAndExecute() public {
        bytes memory data = abi.encodeWithSelector(TargetMock.setValue.selector, 42);
        uint256 eta = block.timestamp + minDelay + 1 hours;

        bytes32 txHash = timelock.queue(address(target), 0, data, eta);
        assertTrue(timelock.isQueued(txHash));

        // Advance to ETA
        vm.warp(eta);

        timelock.execute(address(target), 0, data, eta);
        assertEq(target.value(), 42);
        assertFalse(timelock.isQueued(txHash));
    }

    function test_RevertIf_ExecutedEarly() public {
        bytes memory data = abi.encodeWithSelector(TargetMock.setValue.selector, 42);
        uint256 eta = block.timestamp + minDelay + 1 hours;

        timelock.queue(address(target), 0, data, eta);

        // Before ETA
        vm.warp(eta - 10);
        vm.expectRevert();
        timelock.execute(address(target), 0, data, eta);
    }
}
