// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {SpendingGuardianHook} from "../src/07_AccountAbstraction/SpendingGuardianHook.sol";

contract SpendingGuardianHookTest is Test {
    SpendingGuardianHook public hook;

    address public account = address(0xAAAA);
    address public trustedDEX = address(0xDDEE);
    address public maliciousContract = address(0x666);

    function setUp() public {
        hook = new SpendingGuardianHook();

        vm.startPrank(account);
        hook.setDailyLimit(10 ether);
        hook.setTargetWhitelisted(trustedDEX, true);
        vm.stopPrank();
    }

    function test_WhitelistingAndDailyLimits() public {
        // Calling non-whitelisted target reverts
        vm.expectRevert(SpendingGuardianHook.TargetNotWhitelisted.selector);
        hook.preCheckExecution(account, maliciousContract, 1 ether);

        // Calling whitelisted target within limit succeeds
        hook.preCheckExecution(account, trustedDEX, 6 ether);

        // Exceeding daily limit reverts
        vm.expectRevert(SpendingGuardianHook.DailySpendingLimitExceeded.selector);
        hook.preCheckExecution(account, trustedDEX, 5 ether);
    }
}
