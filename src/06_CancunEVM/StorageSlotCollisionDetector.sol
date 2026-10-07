// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title StorageSlotCollisionDetector
/// @notice ERC-7201 namespaced storage layout calculator and collision detector.
contract StorageSlotCollisionDetector {
    /// @notice Computes standard ERC-7201 formulaic storage root slot
    /// @param namespaceId The unique namespace identifier (e.g. "openzeppelin.storage.ERC20")
    function computeERC7201Slot(string memory namespaceId) public pure returns (bytes32 slot) {
        bytes32 hashId = keccak256(bytes(namespaceId));
        // slot = keccak256(abi.encode(uint256(keccak256(bytes(id))) - 1)) & ~bytes32(uint256(0xff))
        slot = keccak256(abi.encode(uint256(hashId) - 1)) & ~bytes32(uint256(0xff));
    }

    /// @notice Validates whether two namespace identifiers collide
    function checkNamespaceCollision(string memory namespaceA, string memory namespaceB)
        external
        pure
        returns (bool hasCollision)
    {
        bytes32 slotA = computeERC7201Slot(namespaceA);
        bytes32 slotB = computeERC7201Slot(namespaceB);
        return slotA == slotB;
    }

    /// @notice Checks if a namespace root falls into an active standard sequential storage range
    function checkSequentialSlotOverlap(string memory namespaceId, uint256 startSlot, uint256 count)
        external
        pure
        returns (bool overlaps)
    {
        bytes32 nsSlot = computeERC7201Slot(namespaceId);
        uint256 nsUint = uint256(nsSlot);

        return (nsUint >= startSlot && nsUint < startSlot + count);
    }

    /// @notice Validates that slot fulfills ERC-7201 alignment requirement (ends with 0x00)
    function isERC7201Compliant(bytes32 slot) external pure returns (bool) {
        return uint256(slot) & 0xff == 0;
    }
}
