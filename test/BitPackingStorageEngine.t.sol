// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {BitPackingStorageEngine} from "../src/06_CancunEVM/BitPackingStorageEngine.sol";

contract BitPackingStorageEngineTest is Test {
    BitPackingStorageEngine public engine;
    address public user = address(0xCAFEBABE);

    function setUp() public {
        engine = new BitPackingStorageEngine();
    }

    function test_PackAndUnpackLossless() public view {
        uint8 tier = 4;
        uint8 status = 1;
        uint40 timestamp = 1718000000;
        uint40 score = 999999;

        bytes32 packed = engine.pack(user, tier, status, timestamp, score);
        (address u, uint8 t, uint8 s, uint40 ts, uint40 sc) = engine.unpack(packed);

        assertEq(u, user);
        assertEq(t, tier);
        assertEq(s, status);
        assertEq(ts, timestamp);
        assertEq(sc, score);
    }

    function test_StoreAndInPlaceScoreUpdate() public {
        engine.setRecord(1, user, 2, 1, 1000, 50);

        // Update score in place to 950 without altering user, tier, or timestamp
        engine.updateScore(1, 950);

        (address u, uint8 t, uint8 s, uint40 ts, uint40 sc) = engine.getRecord(1);
        assertEq(u, user);
        assertEq(t, 2);
        assertEq(s, 1);
        assertEq(ts, 1000);
        assertEq(sc, 950);
    }
}
