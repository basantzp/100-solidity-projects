// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {StorageSlotCollisionDetector} from "../src/06_CancunEVM/StorageSlotCollisionDetector.sol";

contract StorageSlotCollisionDetectorTest is Test {
    StorageSlotCollisionDetector public detector;

    function setUp() public {
        detector = new StorageSlotCollisionDetector();
    }

    function test_ComputeERC7201SlotAndCompliance() public view {
        bytes32 slot = detector.computeERC7201Slot("example.storage.vault");
        // Must be compliant (end with 0x00)
        assertTrue(detector.isERC7201Compliant(slot));
        assertEq(uint256(slot) & 0xff, 0);
    }

    function test_CollisionDetection() public view {
        bool collision = detector.checkNamespaceCollision("namespace.A", "namespace.B");
        assertFalse(collision);

        bool selfCollision = detector.checkNamespaceCollision("namespace.A", "namespace.A");
        assertTrue(selfCollision);
    }
}
