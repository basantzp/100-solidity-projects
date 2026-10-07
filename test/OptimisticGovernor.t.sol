// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {OptimisticGovernor} from "../src/03_Governance/OptimisticGovernor.sol";

contract TargetExecutionContract {
    uint256 public count;

    function triggerAction() external {
        count += 1;
    }
}

contract OptimisticGovernorTest is Test {
    OptimisticGovernor public governor;
    TargetExecutionContract public target;

    address public arbiter = address(0xAA);
    address public asserter = address(0xBB);

    function setUp() public {
        vm.warp(10_000);
        governor = new OptimisticGovernor(arbiter);
        target = new TargetExecutionContract();

        vm.deal(asserter, 10 ether);
    }

    function test_AssertAndExecuteUnchallenged() public {
        bytes memory actionData = abi.encodeWithSignature("triggerAction()");

        vm.prank(asserter);
        uint256 propId =
            governor.assertProposal{value: 1 ether}(keccak256("upgrade explanation"), address(target), actionData);

        // Before challenge period ends, cannot execute
        vm.expectRevert(OptimisticGovernor.ChallengeWindowActive.selector);
        governor.executeUnchallenged(propId);

        // Fast forward 3 days
        vm.warp(10_000 + 3 days + 1);

        governor.executeUnchallenged(propId);

        // Target action was triggered and bond refunded to asserter
        assertEq(target.count(), 1);
        assertEq(asserter.balance, 10 ether);
    }
}
