// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title CustomYulMemoryAllocator
/// @notice Assembly-level memory pointer management and custom bump allocation.
contract CustomYulMemoryAllocator {
    // --- Events ---
    event MemoryAllocated(uint256 offset, uint256 size);

    uint256 public freeMemOffset = 0x80;

    /// @notice Allocates a contiguous chunk of memory using custom bump pointer
    function allocate(uint256 size) external returns (uint256 memPtr) {
        memPtr = freeMemOffset;
        uint256 roundedSize = ((size + 31) / 32) * 32;
        freeMemOffset += roundedSize;

        assembly {
            // Also update EVM 0x40 memory pointer
            mstore(0x40, add(memPtr, roundedSize))
        }
        emit MemoryAllocated(memPtr, size);
    }

    /// @notice Fast packed memory copy of an array without standard ABI layout overhead
    function packDataInMemory(uint256[] calldata values) external pure returns (bytes memory result) {
        assembly {
            let length := values.length
            let byteSize := mul(length, 32)
            result := mload(0x40)
            mstore(result, byteSize)

            let dest := add(result, 32)
            calldatacopy(dest, values.offset, byteSize)
            mstore(0x40, add(dest, byteSize))
        }
    }

    /// @notice Reads 32 bytes directly from an allocated memory address
    function readMemoryWord(uint256 memPtr) external pure returns (bytes32 val) {
        assembly {
            val := mload(memPtr)
        }
    }
}
