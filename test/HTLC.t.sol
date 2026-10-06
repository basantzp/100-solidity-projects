// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {HTLC} from "../src/05_Cryptographic/HTLC.sol";

contract HTLCTest is Test {
    HTLC htlc;
    address alice = address(0x1);
    address bob = address(0x2);

    bytes32 secret = bytes32("superSecretValue");
    bytes32 hashlock;

    function setUp() public {
        htlc = new HTLC();
        hashlock = sha256(abi.encodePacked(secret));
        vm.deal(alice, 10 ether);
    }

    function test_LockAndWithdrawWithSecret() public {
        uint256 timelock = block.timestamp + 2 days;

        vm.prank(alice);
        bytes32 contractId = htlc.lock{value: 5 ether}(bob, hashlock, timelock);

        assertEq(address(htlc).balance, 5 ether);

        // Bob withdraws by revealing secret
        vm.prank(bob);
        htlc.withdraw(contractId, secret);

        assertEq(bob.balance, 5 ether);
        assertEq(address(htlc).balance, 0);
    }

    function test_RefundAfterTimelockExpires() public {
        uint256 timelock = block.timestamp + 1 days;

        vm.prank(alice);
        bytes32 contractId = htlc.lock{value: 3 ether}(bob, hashlock, timelock);

        // Bob didn't claim, advance past timelock
        vm.warp(block.timestamp + 1 days + 1);

        vm.prank(alice);
        htlc.refund(contractId);

        assertEq(alice.balance, 10 ether);
    }
}
