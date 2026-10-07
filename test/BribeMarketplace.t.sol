// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {BribeMarketplace} from "../src/03_Governance/BribeMarketplace.sol";
import {ERC20Votes} from "../src/01_Tokens/ERC20Votes.sol";

contract BribeMarketplaceTest is Test {
    BribeMarketplace public marketplace;
    ERC20Votes public rewardToken;

    address public sponsor = address(0x590);
    address public voter1 = address(0x701);
    address public voter2 = address(0x702);

    function setUp() public {
        vm.warp(10_000);
        marketplace = new BribeMarketplace();
        rewardToken = new ERC20Votes("Bribe Reward", "BRB");

        rewardToken.mint(sponsor, 1000e18);
        vm.prank(sponsor);
        rewardToken.approve(address(marketplace), type(uint256).max);
    }

    function test_DepositBribeAndClaimProportional() public {
        // Sponsor creates 100 reward bribe pool expiring at 20_000
        vm.prank(sponsor);
        uint256 poolId = marketplace.createBribePool(address(rewardToken), 100e18, 20_000);

        // Record votes: voter1 (75 votes), voter2 (25 votes)
        marketplace.recordVote(poolId, voter1, 75e18);
        marketplace.recordVote(poolId, voter2, 25e18);

        // Before deadline, claiming reverts
        vm.prank(voter1);
        vm.expectRevert(BribeMarketplace.VotingStillActive.selector);
        marketplace.claimBribe(poolId);

        // Fast-forward past deadline
        vm.warp(20_001);

        // Voter 1 claims 75% -> 75 tokens
        vm.prank(voter1);
        uint256 claim1 = marketplace.claimBribe(poolId);
        assertEq(claim1, 75e18);
        assertEq(rewardToken.balanceOf(voter1), 75e18);

        // Voter 2 claims 25% -> 25 tokens
        vm.prank(voter2);
        uint256 claim2 = marketplace.claimBribe(poolId);
        assertEq(claim2, 25e18);
        assertEq(rewardToken.balanceOf(voter2), 25e18);
    }
}
