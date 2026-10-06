// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title BitPackingStorageEngine
/// @notice Ultra gas-optimized user profile storage packing 5 fields into a single 256-bit EVM word.
/// @dev Slot layout (256 bits total):
/// [bits 0..159   : 160 bits] user address
/// [bits 160..167 :   8 bits] tier (uint8)
/// [bits 168..175 :   8 bits] status (uint8)
/// [bits 176..215 :  40 bits] timestamp (uint40)
/// [bits 216..255 :  40 bits] score (uint40)
contract BitPackingStorageEngine {
    // --- Constants & Bitmasks ---
    uint256 private constant ADDR_MASK = (1 << 160) - 1;
    uint256 private constant UINT8_MASK = 0xFF;
    uint256 private constant UINT40_MASK = (1 << 40) - 1;

    uint256 private constant TIER_SHIFT = 160;
    uint256 private constant STATUS_SHIFT = 168;
    uint256 private constant TIMESTAMP_SHIFT = 176;
    uint256 private constant SCORE_SHIFT = 216;

    // Single storage slot per user ID!
    mapping(uint256 => bytes32) private _packedRecords;

    event RecordStored(uint256 indexed recordId, address indexed user, uint8 tier, uint40 score);
    event ScoreUpdated(uint256 indexed recordId, uint40 newScore);

    /// @notice Pack five disparate data types into a single bytes32 word
    function pack(address user, uint8 tier, uint8 status, uint40 ts, uint40 score)
        public
        pure
        returns (bytes32 packed)
    {
        assembly {
            let val := and(user, ADDR_MASK)
            val := or(val, shl(TIER_SHIFT, and(tier, UINT8_MASK)))
            val := or(val, shl(STATUS_SHIFT, and(status, UINT8_MASK)))
            val := or(val, shl(TIMESTAMP_SHIFT, and(ts, UINT40_MASK)))
            val := or(val, shl(SCORE_SHIFT, and(score, UINT40_MASK)))
            packed := val
        }
    }

    /// @notice Unpack a bytes32 word into five discrete components
    function unpack(bytes32 packed)
        public
        pure
        returns (address user, uint8 tier, uint8 status, uint40 timestamp, uint40 score)
    {
        uint256 val = uint256(packed);
        user = address(uint160(val & ADDR_MASK));
        tier = uint8((val >> TIER_SHIFT) & UINT8_MASK);
        status = uint8((val >> STATUS_SHIFT) & UINT8_MASK);
        timestamp = uint40((val >> TIMESTAMP_SHIFT) & UINT40_MASK);
        score = uint40((val >> SCORE_SHIFT) & UINT40_MASK);
    }

    /// @notice Store a record using a single SSTORE
    function setRecord(uint256 recordId, address user, uint8 tier, uint8 status, uint40 timestamp, uint40 score)
        external
    {
        bytes32 packed = pack(user, tier, status, timestamp, score);
        _packedRecords[recordId] = packed;
        emit RecordStored(recordId, user, tier, score);
    }

    /// @notice In-place field mutation updating only bits 216..255 without rewriting other fields
    function updateScore(uint256 recordId, uint40 newScore) external {
        bytes32 packed = _packedRecords[recordId];
        uint256 val = uint256(packed);

        // Clear existing score bits: mask out bits 216..255
        uint256 cleared = val & ~(UINT40_MASK << SCORE_SHIFT);
        // Splice in new score
        uint256 updated = cleared | (uint256(newScore) << SCORE_SHIFT);

        _packedRecords[recordId] = bytes32(updated);
        emit ScoreUpdated(recordId, newScore);
    }

    function getRecord(uint256 recordId)
        external
        view
        returns (address user, uint8 tier, uint8 status, uint40 timestamp, uint40 score)
    {
        return unpack(_packedRecords[recordId]);
    }
}
