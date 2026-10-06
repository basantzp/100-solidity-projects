// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {PaymentSplitter} from "../src/03_Governance/PaymentSplitter.sol";

contract PaymentSplitterTest is Test {
    PaymentSplitter public splitter;
    address public alice = address(0xA11CE);
    address public bob = address(0xB0B);

    function setUp() public {
        address[] memory payees = new address[](2);
        payees[0] = alice;
        payees[1] = bob;

        uint256[] memory shares = new uint256[](2);
        shares[0] = 70; // 70%
        shares[1] = 30; // 30%

        splitter = new PaymentSplitter(payees, shares);
    }

    function test_SplitPaymentProportionally() public {
        // Send 10 ETH to splitter
        vm.deal(address(this), 10 ether);
        (bool sent,) = address(splitter).call{value: 10 ether}("");
        assertTrue(sent);

        assertEq(splitter.releasable(alice), 7 ether);
        assertEq(splitter.releasable(bob), 3 ether);

        uint256 aliceBefore = alice.balance;
        splitter.release(payable(alice));
        assertEq(alice.balance - aliceBefore, 7 ether);

        uint256 bobBefore = bob.balance;
        splitter.release(payable(bob));
        assertEq(bob.balance - bobBefore, 3 ether);
    }

    function test_SubsequentFundingReleasesCorrectly() public {
        vm.deal(address(this), 10 ether);
        (bool s1,) = address(splitter).call{value: 10 ether}("");
        assertTrue(s1);

        splitter.release(payable(alice)); // Alice gets 7 ETH

        // Send additional 10 ETH
        vm.deal(address(this), 10 ether);
        (bool s2,) = address(splitter).call{value: 10 ether}("");
        assertTrue(s2);

        // Alice is now owed 7 more ETH (70% of new 10 ETH)
        assertEq(splitter.releasable(alice), 7 ether);
        // Bob is owed 6 ETH (30% of total 20 ETH)
        assertEq(splitter.releasable(bob), 6 ether);
    }

    function test_RevertIf_NothingDue() public {
        vm.expectRevert(PaymentSplitter.NothingDue.selector);
        splitter.release(payable(alice));
    }
}
