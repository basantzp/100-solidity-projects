// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {SpendingLimitAccount} from "../src/03_Governance/SpendingLimitAccount.sol";

contract SpendingLimitAccountTest is Test {
    SpendingLimitAccount public account;
    address public owner = address(this);
    address public operator = address(0xAA);
    address public recipient = address(0xBB);

    function setUp() public {
        account = new SpendingLimitAccount(1 ether); // 1 ETH / day limit
        account.setSpenderAuthorization(operator, true);
        vm.deal(address(account), 10 ether);
    }

    function test_OperatorCanWithdrawWithinLimit() public {
        vm.prank(operator);
        account.withdraw(payable(recipient), 0.6 ether);

        assertEq(recipient.balance, 0.6 ether);
        assertEq(account.remainingDailyLimit(), 0.4 ether);
    }

    function test_OperatorExceedingLimitReverts() public {
        vm.prank(operator);
        account.withdraw(payable(recipient), 0.8 ether);

        // Attempting to withdraw another 0.5 ETH exceeds remaining 0.2 ETH
        vm.prank(operator);
        vm.expectRevert(
            abi.encodeWithSelector(SpendingLimitAccount.ExceedsSpendingLimit.selector, 0.5 ether, 0.2 ether)
        );
        account.withdraw(payable(recipient), 0.5 ether);
    }

    function test_LimitResetsOnNextDay() public {
        vm.prank(operator);
        account.withdraw(payable(recipient), 1 ether);
        assertEq(account.remainingDailyLimit(), 0);

        // Advance 1 day
        vm.warp(block.timestamp + 1 days + 1);

        assertEq(account.remainingDailyLimit(), 1 ether);

        vm.prank(operator);
        account.withdraw(payable(recipient), 0.5 ether);
        assertEq(recipient.balance, 1.5 ether);
    }

    function test_OwnerBypassesLimit() public {
        account.withdraw(payable(recipient), 5 ether);
        assertEq(recipient.balance, 5 ether);
    }
}
