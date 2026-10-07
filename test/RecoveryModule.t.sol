// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {RecoveryModule} from "../src/07_AccountAbstraction/RecoveryModule.sol";

contract RecoveryModuleTest is Test {
    RecoveryModule public module;

    address public account = address(0xAAAA);
    address public g1 = address(0x1);
    address public g2 = address(0x2);
    address public newOwner = address(0x3);

    function setUp() public {
        vm.warp(10_000);
        module = new RecoveryModule();

        address[] memory guardians = new address[](2);
        guardians[0] = g1;
        guardians[1] = g2;

        vm.prank(account);
        module.setupGuardians(guardians, 2);
    }

    function test_InitiateConfirmAndExecuteRecovery() public {
        vm.prank(g1);
        module.initiateRecovery(account, newOwner);

        vm.prank(g2);
        module.confirmRecovery(account);

        // Before timelock expires
        vm.expectRevert(RecoveryModule.RecoveryNotDue.selector);
        module.executeRecovery(account);

        // Fast forward 1 day
        vm.warp(10_000 + 1 days + 1);

        address recoveredOwner = module.executeRecovery(account);
        assertEq(recoveredOwner, newOwner);
    }
}
