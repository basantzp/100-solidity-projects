// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {SoulboundToken} from "../src/01_Tokens/SoulboundToken.sol";

contract SoulboundTokenTest is Test {
    SoulboundToken public sbt;
    address public admin = address(this);
    address public alice = address(0xA11CE);
    address public bob = address(0xB0B);

    function setUp() public {
        sbt = new SoulboundToken("Identity Badge", "BADGE");
    }

    function test_IssueBadge() public {
        sbt.issue(alice, 1, "ipfs://badge-1");

        assertEq(sbt.balanceOf(alice), 1);
        assertEq(sbt.ownerOf(1), alice);
        assertEq(sbt.tokenURI(1), "ipfs://badge-1");
    }

    function test_TransferReverts() public {
        sbt.issue(alice, 1, "ipfs://badge-1");

        vm.prank(alice);
        vm.expectRevert(SoulboundToken.NonTransferable.selector);
        sbt.transferFrom(alice, bob, 1);

        vm.prank(alice);
        vm.expectRevert(SoulboundToken.NonTransferable.selector);
        sbt.approve(bob, 1);
    }

    function test_RevokeByIssuerOrHolder() public {
        sbt.issue(alice, 1, "ipfs://badge-1");

        // Alice (the holder) revokes her badge
        vm.prank(alice);
        sbt.revoke(1);

        assertEq(sbt.balanceOf(alice), 0);
        vm.expectRevert(SoulboundToken.TokenDoesNotExist.selector);
        sbt.ownerOf(1);
    }

    function test_RevokeByUnauthorizedReverts() public {
        sbt.issue(alice, 1, "ipfs://badge-1");

        vm.prank(bob);
        vm.expectRevert(SoulboundToken.NotAuthorized.selector);
        sbt.revoke(1);
    }
}
