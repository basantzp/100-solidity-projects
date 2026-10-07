// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title StorageMigrator
/// @notice Safe slot migration manager for upgradeable contracts transitioning storage layouts.
contract StorageMigrator {
    // --- Errors ---
    error Unauthorized();
    error MigrationAlreadyCompleted();
    error ArrayLengthMismatch();

    // --- Events ---
    event MigrationExecuted(address indexed target, uint256 slotsMigrated);

    address public immutable owner;
    mapping(address => bool) public migrated;

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /// @notice Migrates storage keys from old slots to new destination slots
    function migrateSlots(bytes32[] calldata oldSlots, bytes32[] calldata newSlots, bytes32[] calldata expectedValues)
        external
        onlyOwner
    {
        if (oldSlots.length != newSlots.length || newSlots.length != expectedValues.length) {
            revert ArrayLengthMismatch();
        }

        for (uint256 i = 0; i < oldSlots.length; i++) {
            bytes32 oldSlot = oldSlots[i];
            bytes32 newSlot = newSlots[i];
            bytes32 expectedVal = expectedValues[i];

            bytes32 currentVal;
            assembly {
                currentVal := sload(oldSlot)
            }
            require(currentVal == expectedVal, "Value mismatch in source slot");

            assembly {
                // Copy to new slot and clear old slot
                sstore(newSlot, currentVal)
                sstore(oldSlot, 0)
            }
        }

        emit MigrationExecuted(address(this), oldSlots.length);
    }

    function readSlot(bytes32 slot) external view returns (bytes32 val) {
        assembly {
            val := sload(slot)
        }
    }

    function writeSlot(bytes32 slot, bytes32 val) external onlyOwner {
        assembly {
            sstore(slot, val)
        }
    }
}
