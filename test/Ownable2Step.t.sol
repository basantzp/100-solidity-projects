// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {Ownable2Step} from "../src/04_Security/Ownable2Step.sol";

contract MockOwnable is Ownable2Step {}

contract Ownable2StepTest is Test {
    MockOwnable ownable;
    address alice = address(0x1);
    address bob = address(0x2);

    function setUp() public {
        ownable = new MockOwnable();
    }

    function test_InitialOwner() public view {
        assertEq(ownable.owner(), address(this));
        assertEq(ownable.pendingOwner(), address(0));
    }

    function test_TwoStepTransfer() public {
        ownable.transferOwnership(alice);
        assertEq(ownable.owner(), address(this));
        assertEq(ownable.pendingOwner(), alice);

        // Bob cannot accept
        vm.prank(bob);
        vm.expectRevert(Ownable2Step.NotPendingOwner.selector);
        ownable.acceptOwnership();

        // Alice accepts
        vm.prank(alice);
        ownable.acceptOwnership();

        assertEq(ownable.owner(), alice);
        assertEq(ownable.pendingOwner(), address(0));
    }
}
