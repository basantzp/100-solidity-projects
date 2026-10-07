// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {ConvictionVoting} from "../src/03_Governance/ConvictionVoting.sol";
import {ERC20Votes} from "../src/01_Tokens/ERC20Votes.sol";

contract ConvictionVotingTest is Test {
    ConvictionVoting public cv;
    ERC20Votes public token;

    address payable public beneficiary = payable(address(0x9999));
    address public staker = address(0x5555);

    function setUp() public {
        vm.warp(10_000);
        token = new ERC20Votes("Governance Token", "GOV");
        cv = new ConvictionVoting(address(token));

        token.mint(staker, 1000e18);
        vm.deal(address(cv), 10 ether);

        vm.prank(staker);
        token.approve(address(cv), type(uint256).max);
    }

    function test_ContinuousConvictionAccumulationAndExecution() public {
        // Create proposal requesting 1 ETH with conviction threshold of 1000 * 100 seconds
        uint256 propId = cv.createProposal(beneficiary, 1 ether, 100_000e18);

        // Staker stakes 1000 tokens
        vm.prank(staker);
        cv.stake(propId, 1000e18);

        // Warp 50 seconds -> conviction = 50,000e18 (< threshold)
        vm.warp(10_050);
        vm.expectRevert(ConvictionVoting.ThresholdNotMet.selector);
        cv.executeProposal(propId);

        // Warp another 51 seconds -> conviction = 101,000e18 (>= threshold)
        vm.warp(10_101);
        cv.executeProposal(propId);

        assertEq(beneficiary.balance, 1 ether);
    }
}
