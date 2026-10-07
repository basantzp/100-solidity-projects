// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title ExtsloadExpose
/// @notice EIP-2330 / Cancun standard contract exposing extsload and exttload for off-chain proofs and batch readers.
contract ExtsloadExpose {
    // --- State Variables ---
    address public immutable owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /// @notice Allows owner to write arbitrary storage slot for demonstration
    function writeSlot(bytes32 slot, bytes32 value) external onlyOwner {
        assembly {
            sstore(slot, value)
        }
    }

    /// @notice Reads single 32-byte storage slot
    function extsload(bytes32 slot) external view returns (bytes32 value) {
        assembly {
            value := sload(slot)
        }
    }

    /// @notice Reads array of storage slots in a single batch staticcall
    function extsload(bytes32[] calldata slots) external view returns (bytes32[] memory values) {
        values = new bytes32[](slots.length);
        for (uint256 i = 0; i < slots.length; i++) {
            bytes32 slot = slots[i];
            bytes32 val;
            assembly {
                val := sload(slot)
            }
            values[i] = val;
        }
    }

    /// @notice Reads single transient storage slot using Cancun EIP-1153 tload
    function exttload(bytes32 slot) external view returns (bytes32 value) {
        assembly {
            value := tload(slot)
        }
    }

    /// @notice Writes transient storage slot for intra-tx reading
    function writeTransientSlot(bytes32 slot, bytes32 value) external {
        assembly {
            tstore(slot, value)
        }
    }

    /// @notice Atomic intra-transaction helper to write and read transient storage
    function atomicTransientTest(bytes32 slot, bytes32 value) external returns (bytes32 readValue) {
        assembly {
            tstore(slot, value)
            readValue := tload(slot)
        }
    }
}
