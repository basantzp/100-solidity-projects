// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title BitMapFlagRegistry
/// @notice Ultra gas-efficient boolean flag registry packing 256 booleans per 32-byte storage slot.
/// @dev Slashes boolean storage overhead by 99% compared to traditional mappings.
contract BitMapFlagRegistry {
    // --- State Variables ---
    mapping(uint256 => uint256) private _bitmap;

    event FlagSet(uint256 indexed index);
    event FlagUnset(uint256 indexed index);

    /// @notice Check if flag at index is true
    function get(uint256 index) public view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return (_bitmap[bucket] & mask) != 0;
    }

    /// @notice Set flag at index to true
    function set(uint256 index) public {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        _bitmap[bucket] |= mask;
        emit FlagSet(index);
    }

    /// @notice Set flag at index to false
    function unset(uint256 index) public {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        _bitmap[bucket] &= ~mask;
        emit FlagUnset(index);
    }

    /// @notice Set flag at index to given boolean state
    function setTo(uint256 index, bool value) external {
        if (value) {
            set(index);
        } else {
            unset(index);
        }
    }
}
