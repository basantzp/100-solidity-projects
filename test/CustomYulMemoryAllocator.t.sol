// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {CustomYulMemoryAllocator} from "../src/06_CancunEVM/CustomYulMemoryAllocator.sol";

contract CustomYulMemoryAllocatorTest is Test {
    CustomYulMemoryAllocator public allocator;

    function setUp() public {
        allocator = new CustomYulMemoryAllocator();
    }

    function test_AllocateMemory() public {
        uint256 ptr1 = allocator.allocate(64);
        uint256 ptr2 = allocator.allocate(32);

        // ptr2 should be offset by 64 from ptr1
        assertEq(ptr2, ptr1 + 64);
    }

    function test_PackDataInMemory() public view {
        uint256[] memory data = new uint256[](3);
        data[0] = 0x111;
        data[1] = 0x222;
        data[2] = 0x333;

        bytes memory packed = allocator.packDataInMemory(data);
        assertEq(packed.length, 96);
    }
}
