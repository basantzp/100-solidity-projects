// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {ExtsloadExpose} from "../src/06_CancunEVM/ExtsloadExpose.sol";

contract ExtsloadExposeTest is Test {
    ExtsloadExpose public reader;

    function setUp() public {
        reader = new ExtsloadExpose();
    }

    function test_ExtsloadSingleAndBatch() public {
        bytes32 slot0 = bytes32(uint256(100));
        bytes32 slot1 = bytes32(uint256(101));

        reader.writeSlot(slot0, bytes32("HELLO"));
        reader.writeSlot(slot1, bytes32("WORLD"));

        assertEq(reader.extsload(slot0), bytes32("HELLO"));
        assertEq(reader.extsload(slot1), bytes32("WORLD"));

        bytes32[] memory slots = new bytes32[](2);
        slots[0] = slot0;
        slots[1] = slot1;

        bytes32[] memory vals = reader.extsload(slots);
        assertEq(vals[0], bytes32("HELLO"));
        assertEq(vals[1], bytes32("WORLD"));
    }

    function test_ExttloadTransientStorage() public {
        bytes32 tslot = bytes32(uint256(0xBEEF));
        bytes32 val = reader.atomicTransientTest(tslot, bytes32("TRANSIENT_VAL"));

        assertEq(val, bytes32("TRANSIENT_VAL"));
    }
}
