// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {StreamingPaymentPayroll} from "../src/03_Governance/StreamingPaymentPayroll.sol";
import {ERC20Votes} from "../src/01_Tokens/ERC20Votes.sol";

contract StreamingPaymentPayrollTest is Test {
    StreamingPaymentPayroll public payroll;
    ERC20Votes public token;

    address public employer = address(0xEE);
    address public employee = address(0xAA);

    function setUp() public {
        token = new ERC20Votes("Salary Token", "PAY");
        payroll = new StreamingPaymentPayroll();

        token.mint(employer, 100_000e18);

        vm.prank(employer);
        token.approve(address(payroll), type(uint256).max);
    }

    function test_LinearStreamAccrualAndWithdrawal() public {
        uint256 start = block.timestamp + 10;
        uint256 stop = start + 1000; // 1,000 seconds
        uint256 deposit = 10_000e18; // 10 tokens per second

        vm.prank(employer);
        uint256 streamId = payroll.createStream(employee, address(token), deposit, start, stop);

        // Advance 500 seconds into the stream (50% vested)
        vm.warp(start + 500);

        assertEq(payroll.streamedBalance(streamId), 5_000e18);
        assertEq(payroll.availableToWithdraw(streamId), 5_000e18);

        // Employee withdraws 2,000 tokens
        uint256 empBefore = token.balanceOf(employee);
        vm.prank(employee);
        payroll.withdrawFromStream(streamId, 2_000e18);

        assertEq(token.balanceOf(employee) - empBefore, 2_000e18);
        assertEq(payroll.availableToWithdraw(streamId), 3_000e18);

        // Advance to completion
        vm.warp(stop + 10);
        assertEq(payroll.availableToWithdraw(streamId), 8_000e18);
    }

    function test_CancelStreamRefundsUnvestedPortion() public {
        uint256 start = block.timestamp + 10;
        uint256 stop = start + 1000;
        uint256 deposit = 10_000e18;

        vm.prank(employer);
        uint256 streamId = payroll.createStream(employee, address(token), deposit, start, stop);

        // Advance 400 seconds (4,000 vested, 6,000 unvested)
        vm.warp(start + 400);

        uint256 empBefore = token.balanceOf(employee);
        uint256 bossBefore = token.balanceOf(employer);

        vm.prank(employer);
        payroll.cancelStream(streamId);

        // Employee receives 4,000 vested
        assertEq(token.balanceOf(employee) - empBefore, 4_000e18);
        // Employer refunded 6,000 unvested
        assertEq(token.balanceOf(employer) - bossBefore, 6_000e18);
    }
}
