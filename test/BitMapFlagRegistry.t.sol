// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {BitMapFlagRegistry} from "../src/06_CancunEVM/BitMapFlagRegistry.sol";

contract BitMapFlagRegistryTest is Test {
    BitMapFlagRegistry public registry;

    function setUp() public {
        registry = new BitMapFlagRegistry();
    }

    function test_SetAndGetFlagsAcrossBuckets() public {
        assertFalse(registry.get(0));
        assertFalse(registry.get(255));
        assertFalse(registry.get(256)); // Second bucket
        assertFalse(registry.get(1024)); // Fifth bucket

        registry.set(0);
        registry.set(255);
        registry.set(256);
        registry.set(1024);

        assertTrue(registry.get(0));
        assertTrue(registry.get(255));
        assertTrue(registry.get(256));
        assertTrue(registry.get(1024));

        // Neighboring unassigned bits remain false
        assertFalse(registry.get(1));
        assertFalse(registry.get(254));
        assertFalse(registry.get(257));
    }

    function test_UnsetFlag() public {
        registry.set(42);
        assertTrue(registry.get(42));

        registry.unset(42);
        assertFalse(registry.get(42));
    }

    function testFuzz_SetAndGet(uint256 index) public {
        vm.assume(index < 100_000); // Test across ~400 buckets
        assertFalse(registry.get(index));

        registry.set(index);
        assertTrue(registry.get(index));

        registry.unset(index);
        assertFalse(registry.get(index));
    }
}
