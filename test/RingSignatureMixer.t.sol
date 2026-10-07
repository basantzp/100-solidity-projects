// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {RingSignatureMixer} from "../src/05_Cryptographic/RingSignatureMixer.sol";

contract RingSignatureMixerTest is Test {
    RingSignatureMixer public mixer;

    address public depositor = address(0xDE90);
    address payable public recipient = payable(address(0x8888));

    function setUp() public {
        mixer = new RingSignatureMixer();
        vm.deal(depositor, 10 ether);
    }

    function test_DepositAndWithdraw() public {
        bytes32 secret = keccak256(abi.encodePacked("my-secret-preimage"));
        bytes32 nullifier = keccak256(abi.encodePacked(secret, "nullifier"));
        bytes32 commitment = keccak256(abi.encodePacked(secret, nullifier));

        // Deposit 1 ETH
        vm.prank(depositor);
        mixer.deposit{value: 1 ether}(commitment);

        assertEq(mixer.totalDeposits(), 1);
        assertEq(address(mixer).balance, 1 ether);

        // Withdraw to unlinked recipient
        mixer.withdraw(nullifier, recipient, commitment);

        assertEq(address(mixer).balance, 0);
        assertEq(recipient.balance, 1 ether);
        assertTrue(mixer.nullifierSpent(nullifier));

        // Attempting to spend the same nullifier reverts
        vm.expectRevert(RingSignatureMixer.NullifierAlreadySpent.selector);
        mixer.withdraw(nullifier, recipient, commitment);
    }
}
