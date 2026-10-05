// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {MultiSigWallet} from "../src/03_Governance/MultiSigWallet.sol";

contract MultiSigWalletTest is Test {
    MultiSigWallet wallet;

    address owner1 = address(0x1);
    address owner2 = address(0x2);
    address owner3 = address(0x3);
    address recipient = address(0x4);

    address[] owners;

    function setUp() public {
        owners = new address[](3);
        owners[0] = owner1;
        owners[1] = owner2;
        owners[2] = owner3;

        // 2 of 3 required confirmations
        wallet = new MultiSigWallet(owners, 2);

        // Fund wallet
        vm.deal(address(wallet), 10 ether);
    }

    function test_InitialConfiguration() public view {
        assertEq(wallet.numConfirmationsRequired(), 2);
        assertTrue(wallet.isOwner(owner1));
        assertTrue(wallet.isOwner(owner2));
        assertTrue(wallet.isOwner(owner3));
        assertFalse(wallet.isOwner(recipient));
    }

    function test_SubmitConfirmExecuteTransaction() public {
        // Owner 1 submits tx to send 1 ether to recipient
        vm.prank(owner1);
        uint256 txIndex = wallet.submitTransaction(recipient, 1 ether, "");

        assertEq(txIndex, 0);
        assertEq(wallet.getTransactionCount(), 1);

        // Cannot execute before quorum
        vm.prank(owner1);
        vm.expectRevert();
        wallet.executeTransaction(0);

        // Owner 1 confirms
        vm.prank(owner1);
        wallet.confirmTransaction(0);

        // Owner 2 confirms (reaches quorum 2 of 3)
        vm.prank(owner2);
        wallet.confirmTransaction(0);

        // Owner 3 executes
        uint256 recipientBalBefore = recipient.balance;
        vm.prank(owner3);
        wallet.executeTransaction(0);

        assertEq(recipient.balance - recipientBalBefore, 1 ether);
    }

    function test_RevokeConfirmation() public {
        vm.prank(owner1);
        wallet.submitTransaction(recipient, 1 ether, "");

        vm.prank(owner1);
        wallet.confirmTransaction(0);

        assertTrue(wallet.isConfirmed(0, owner1));

        vm.prank(owner1);
        wallet.revokeConfirmation(0);

        assertFalse(wallet.isConfirmed(0, owner1));
    }

    function test_RevertIf_NonOwnerSubmits() public {
        vm.prank(recipient);
        vm.expectRevert(MultiSigWallet.NotOwner.selector);
        wallet.submitTransaction(recipient, 1 ether, "");
    }
}
