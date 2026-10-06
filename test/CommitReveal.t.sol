// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {CommitReveal} from "../src/05_Cryptographic/CommitReveal.sol";

contract CommitRevealTest is Test {
    CommitReveal cr;
    address alice = address(0x1);
    address bob = address(0x2);

    bytes32 secretAlice = bytes32("secret123");
    bytes32 secretBob = bytes32("secret456");

    function setUp() public {
        cr = new CommitReveal(1 hours, 1 hours);
    }

    function test_CommitAndRevealFlow() public {
        bytes32 commitAlice = cr.getSaltedHash(1, secretAlice, alice);
        bytes32 commitBob = cr.getSaltedHash(2, secretBob, bob);

        // Commit phase
        vm.prank(alice);
        cr.commit(commitAlice);

        vm.prank(bob);
        cr.commit(commitBob);

        // Reveal phase
        vm.warp(block.timestamp + 1 hours + 1);

        vm.prank(alice);
        cr.reveal(1, secretAlice);

        vm.prank(bob);
        cr.reveal(2, secretBob);

        assertEq(cr.totalVotesForOption1(), 1);
        assertEq(cr.totalVotesForOption2(), 1);
    }

    function test_RevertIf_RevealWithWrongSecret() public {
        bytes32 commitAlice = cr.getSaltedHash(1, secretAlice, alice);

        vm.prank(alice);
        cr.commit(commitAlice);

        vm.warp(block.timestamp + 1 hours + 1);

        vm.prank(alice);
        vm.expectRevert(CommitReveal.HashMismatch.selector);
        cr.reveal(1, bytes32("wrongSecret"));
    }
}
