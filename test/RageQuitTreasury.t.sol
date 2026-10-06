// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {RageQuitTreasury} from "../src/03_Governance/RageQuitTreasury.sol";
import {ERC20Votes} from "../src/01_Tokens/ERC20Votes.sol";

contract RageQuitTreasuryTest is Test {
    RageQuitTreasury public treasury;
    ERC20Votes public asset;

    address public alice = address(0xA11CE);
    address public bob = address(0xB0B);

    function setUp() public {
        asset = new ERC20Votes("Treasury Asset", "TRSY");
        treasury = new RageQuitTreasury(address(asset));

        asset.mint(alice, 10_000e18);
        asset.mint(bob, 10_000e18);

        vm.prank(alice);
        asset.approve(address(treasury), type(uint256).max);

        vm.prank(bob);
        asset.approve(address(treasury), type(uint256).max);
    }

    function test_JoinAndProportionalRageQuit() public {
        // Alice joins with 60 shares (60% ownership)
        vm.prank(alice);
        treasury.join(60e18);

        // Bob joins with 40 shares (40% ownership)
        vm.prank(bob);
        treasury.join(40e18);

        assertEq(treasury.totalShares(), 100e18);

        // Treasury receives external endowment of 100 tokens (now 200 total assets!)
        asset.mint(address(treasury), 100e18);

        // Alice ragequits all 60 shares
        // Her 60% slice of 200 total tokens = 120 tokens!
        uint256 aliceBefore = asset.balanceOf(alice);
        vm.prank(alice);
        uint256 payout = treasury.rageQuit(60e18);

        assertEq(payout, 120e18);
        assertEq(asset.balanceOf(alice) - aliceBefore, 120e18);
        assertEq(treasury.shares(alice), 0);
        assertEq(treasury.totalShares(), 40e18); // Only Bob's 40 shares remain
    }

    function test_RageQuitExceedingSharesReverts() public {
        vm.prank(alice);
        treasury.join(10e18);

        vm.prank(alice);
        vm.expectRevert(RageQuitTreasury.InsufficientShares.selector);
        treasury.rageQuit(20e18);
    }
}
