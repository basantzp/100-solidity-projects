// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {QuadraticVotingEngine} from "../src/03_Governance/QuadraticVotingEngine.sol";

contract QuadraticVotingEngineTest is Test {
    QuadraticVotingEngine public engine;
    address public admin = address(this);
    address public alice = address(0xA11CE);
    address public bob = address(0xB0B);

    function setUp() public {
        engine = new QuadraticVotingEngine();
    }

    function test_QuadraticVotingCostScaling() public {
        // Create poll with 3 proposals (0, 1, 2)
        uint256 pollId = engine.createPoll("Ecosystem Grants", 3, 7 days);

        // Register Alice with 100 voice credits
        engine.registerVoter(pollId, alice, 100);

        // Alice casts 3 votes for Proposal 0 (cost = 3^2 = 9 credits)
        vm.prank(alice);
        engine.vote(pollId, 0, 3);

        assertEq(engine.voiceCredits(pollId, alice), 91);
        assertEq(engine.proposalVotes(pollId, 0), 3);

        // Alice increases votes for Proposal 0 from 3 to 10 (cost = 10^2 - 3^2 = 100 - 9 = 91 credits)
        vm.prank(alice);
        engine.vote(pollId, 0, 10);

        assertEq(engine.voiceCredits(pollId, alice), 0);
        assertEq(engine.proposalVotes(pollId, 0), 10);
    }

    function test_InsufficientCreditsReverts() public {
        uint256 pollId = engine.createPoll("Protocol Parameter", 2, 1 days);
        engine.registerVoter(pollId, bob, 20); // Bob has 20 credits

        // Bob tries to cast 5 votes (needs 5^2 = 25 credits > 20 credits)
        vm.prank(bob);
        vm.expectRevert(QuadraticVotingEngine.InsufficientVoiceCredits.selector);
        engine.vote(pollId, 0, 5);
    }
}
