// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {SocialRecoveryWallet} from "../src/03_Governance/SocialRecoveryWallet.sol";

contract SocialRecoveryWalletTest is Test {
    SocialRecoveryWallet public wallet;
    address public owner = address(0x111);
    address public g1 = address(0x221);
    address public g2 = address(0x222);
    address public g3 = address(0x223);
    address public newOwner = address(0x333);

    function setUp() public {
        address[] memory guardians = new address[](3);
        guardians[0] = g1;
        guardians[1] = g2;
        guardians[2] = g3;

        // 2 of 3 guardians required, 1 day delay
        wallet = new SocialRecoveryWallet(owner, guardians, 2, 1 days);
        vm.deal(address(wallet), 5 ether);
    }

    function test_OwnerCanExecute() public {
        address recipient = address(0x888);
        vm.prank(owner);
        wallet.execute(recipient, 1 ether, "");

        assertEq(recipient.balance, 1 ether);
    }

    function test_SuccessfulGuardianRecoveryFlow() public {
        // Guardian 1 initiates recovery
        vm.prank(g1);
        wallet.initiateRecovery(newOwner);

        // Guardian 2 supports recovery (reaches 2/3 threshold)
        vm.prank(g2);
        wallet.supportRecovery(newOwner);

        // Before timelock expires, execution reverts
        vm.expectRevert(SocialRecoveryWallet.TimelockPending.selector);
        wallet.executeRecovery();

        // Warp past 1 day timelock
        vm.warp(block.timestamp + 1 days + 1);

        wallet.executeRecovery();

        assertEq(wallet.owner(), newOwner);
    }

    function test_OwnerCancelsUnauthorizedRecovery() public {
        vm.prank(g1);
        wallet.initiateRecovery(newOwner);

        // Owner detects and cancels
        vm.prank(owner);
        wallet.cancelRecovery();

        (,,, bool active) = wallet.activeRecovery();
        assertFalse(active);
    }
}
