// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {SubscriptionExecutor} from "../src/07_AccountAbstraction/SubscriptionExecutor.sol";
import {ERC20Votes} from "../src/01_Tokens/ERC20Votes.sol";

contract SubscriptionExecutorTest is Test {
    SubscriptionExecutor public executor;
    ERC20Votes public token;

    address public subscriber = address(0x101);
    address public merchant = address(0x202);

    function setUp() public {
        vm.warp(10_000);
        executor = new SubscriptionExecutor();
        token = new ERC20Votes("USDC", "USDC");

        token.mint(subscriber, 1000e18);
        vm.prank(subscriber);
        token.approve(address(executor), type(uint256).max);
    }

    function test_CreateAndExecuteBillingCycle() public {
        // 10 USDC every 30 days
        vm.prank(subscriber);
        bytes32 subId = executor.createSubscription(merchant, address(token), 10e18, 30 days);

        // Cannot bill immediately
        vm.expectRevert(SubscriptionExecutor.SubscriptionNotDue.selector);
        executor.executeBilling(subId);

        // Fast forward 30 days
        vm.warp(10_000 + 30 days);

        executor.executeBilling(subId);
        assertEq(token.balanceOf(merchant), 10e18);

        // Billed second cycle after another 30 days
        vm.warp(10_000 + 60 days);
        executor.executeBilling(subId);
        assertEq(token.balanceOf(merchant), 20e18);
    }
}
