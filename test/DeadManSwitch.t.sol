// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {DeadManSwitch} from "../src/03_Governance/DeadManSwitch.sol";

contract DeadManSwitchTest is Test {
    DeadManSwitch public dms;
    address public owner = address(this);
    address public beneficiary = address(0xBEEF);

    function setUp() public {
        // 30 days timeout
        dms = new DeadManSwitch{value: 5 ether}(beneficiary, 30 days);
    }

    function test_PingResetsCountdown() public {
        vm.warp(block.timestamp + 20 days);
        assertFalse(dms.isTriggered());

        dms.ping();
        assertEq(dms.lastHeartbeat(), block.timestamp);

        // 20 more days later (40 days total from start, but 20 days since ping)
        vm.warp(block.timestamp + 20 days);
        assertFalse(dms.isTriggered());
    }

    function test_BeneficiaryClaimsAfterTimeout() public {
        // Advance past 30 days without ping
        vm.warp(block.timestamp + 30 days + 1);
        assertTrue(dms.isTriggered());

        uint256 beneficiaryBefore = beneficiary.balance;
        vm.prank(beneficiary);
        dms.claimInheritance();

        assertEq(beneficiary.balance - beneficiaryBefore, 5 ether);
        assertEq(address(dms).balance, 0);
    }

    function test_PrematureClaimReverts() public {
        vm.warp(block.timestamp + 10 days);

        vm.prank(beneficiary);
        vm.expectRevert();
        dms.claimInheritance();
    }
}
