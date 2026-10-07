// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {MockSanitizedContract, UpgradeSanitizer} from "../src/06_Upgradeability/UpgradeSanitizer.sol";

contract UpgradeSanitizerTest is Test {
    MockSanitizedContract public implementation;

    function setUp() public {
        // In constructor, implementation calls _disableInitializers()
        implementation = new MockSanitizedContract();
    }

    function test_ImplementationLockedAgainstInitialization() public {
        // Direct initialization of implementation contract reverts
        vm.expectRevert(UpgradeSanitizer.InvalidInitialization.selector);
        implementation.initialize(100, address(this));

        // Initialized version is uint64 max
        assertEq(implementation.getInitializedVersion(), type(uint64).max);
    }
}
