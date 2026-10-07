// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {SovereignRollupSettlement} from "../src/09_CrossChain/SovereignRollupSettlement.sol";

contract SovereignRollupSettlementTest is Test {
    SovereignRollupSettlement public rollup;

    address public adjudicator = address(0xAD);
    address public proposer = address(0x10);
    address public challenger = address(0x20);

    function setUp() public {
        vm.warp(10_000);
        rollup = new SovereignRollupSettlement(adjudicator);

        vm.deal(proposer, 10 ether);
        vm.deal(challenger, 10 ether);
    }

    function test_ProposeAndFinalizeUnchallenged() public {
        bytes32 stateRoot = keccak256("valid-state-root");
        bytes32 traceRoot = keccak256("execution-trace");

        vm.prank(proposer);
        uint256 batchId = rollup.proposeBatch{value: 1 ether}(stateRoot, traceRoot);

        // Before challenge window expires
        vm.expectRevert(SovereignRollupSettlement.ChallengePeriodExpired.selector);
        rollup.finalizeUnchallengedBatch(batchId);

        // Warp 7 days
        vm.warp(10_000 + 7 days + 1);

        rollup.finalizeUnchallengedBatch(batchId);
        assertEq(proposer.balance, 10 ether); // Bond refunded
    }

    function test_ChallengeAndAdjudicateDispute() public {
        bytes32 stateRoot = keccak256("invalid-state-root");
        bytes32 traceRoot = keccak256("bad-trace");

        vm.prank(proposer);
        uint256 batchId = rollup.proposeBatch{value: 1 ether}(stateRoot, traceRoot);

        // Challenger detects invalid state root and challenges within window
        vm.prank(challenger);
        rollup.challengeBatch{value: 1 ether}(batchId);

        // Adjudicator verifies one-step fraud proof: proposer loses
        vm.prank(adjudicator);
        rollup.settleDispute(batchId, false);

        // Challenger receives slashed proposer bond + refund = 2 ether
        assertEq(challenger.balance, 11 ether);
    }
}
