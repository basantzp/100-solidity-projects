// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {StorageMigrator} from "../src/06_Upgradeability/StorageMigrator.sol";

contract StorageMigratorTest is Test {
    StorageMigrator public migrator;

    function setUp() public {
        migrator = new StorageMigrator();
    }

    function test_MigrateStorageSlots() public {
        bytes32 oldSlot = bytes32(uint256(5));
        bytes32 newSlot = bytes32(uint256(50));
        bytes32 val = bytes32("PERSISTED_STATE");

        migrator.writeSlot(oldSlot, val);
        assertEq(migrator.readSlot(oldSlot), val);

        bytes32[] memory oldSlots = new bytes32[](1);
        oldSlots[0] = oldSlot;

        bytes32[] memory newSlots = new bytes32[](1);
        newSlots[0] = newSlot;

        bytes32[] memory expectedVals = new bytes32[](1);
        expectedVals[0] = val;

        migrator.migrateSlots(oldSlots, newSlots, expectedVals);

        // Old slot cleared, new slot populated
        assertEq(migrator.readSlot(oldSlot), bytes32(0));
        assertEq(migrator.readSlot(newSlot), val);
    }
}
