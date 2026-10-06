// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {EscrowVault} from "../src/01_Tokens/EscrowVault.sol";

contract EscrowVaultTest is Test {
    EscrowVault public vault;
    address public buyer = address(0xAA);
    address public seller = address(0xBB);
    address public arbiter = address(0xCC);

    function setUp() public {
        vault = new EscrowVault();
        vm.deal(buyer, 10 ether);
    }

    function test_CreateFundAndReleaseByBuyer() public {
        vm.prank(buyer);
        uint256 id = vault.createEscrow(seller, arbiter);

        vm.prank(buyer);
        vault.fundEscrow{value: 2 ether}(id);

        uint256 sellerBefore = seller.balance;

        vm.prank(buyer);
        vault.release(id);

        assertEq(seller.balance - sellerBefore, 2 ether);
    }

    function test_DisputeAndArbiterRefundsBuyer() public {
        vm.prank(buyer);
        uint256 id = vault.createEscrow(seller, arbiter);

        vm.prank(buyer);
        vault.fundEscrow{value: 3 ether}(id);

        // Buyer raises dispute
        vm.prank(buyer);
        vault.dispute(id);

        uint256 buyerBefore = buyer.balance;

        // Arbiter resolves by refunding buyer
        vm.prank(arbiter);
        vault.refund(id);

        assertEq(buyer.balance - buyerBefore, 3 ether);
    }

    function test_RevertIf_UnauthorizedRelease() public {
        vm.prank(buyer);
        uint256 id = vault.createEscrow(seller, arbiter);

        vm.prank(buyer);
        vault.fundEscrow{value: 1 ether}(id);

        // Seller attempts to release to themselves without buyer or arbiter approval
        vm.prank(seller);
        vm.expectRevert(EscrowVault.NotParty.selector);
        vault.release(id);
    }
}
