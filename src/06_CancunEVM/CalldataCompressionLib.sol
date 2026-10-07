// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title CalldataCompressionLib
/// @notice Run-Length Encoding (RLE) and zero-byte calldata compression / decompression for L2 gas savings.
library CalldataCompressionLib {
    uint8 internal constant ZERO_FLAG = 0x00;

    /// @notice Compresses zero-byte sequences in calldata using RLE
    function compress(bytes calldata data) external pure returns (bytes memory) {
        bytes memory compressed = new bytes(data.length * 2 + 1);
        uint256 writePos = 0;
        uint256 len = data.length;

        uint256 i = 0;
        while (i < len) {
            if (data[i] == 0) {
                // Count consecutive zeros (up to 255)
                uint8 zeroCount = 0;
                while (i < len && data[i] == 0 && zeroCount < 255) {
                    zeroCount++;
                    i++;
                }
                compressed[writePos++] = bytes1(ZERO_FLAG);
                compressed[writePos++] = bytes1(zeroCount);
            } else {
                compressed[writePos++] = data[i];
                i++;
            }
        }

        // Resize array to actual written length
        bytes memory trimmed = new bytes(writePos);
        for (uint256 j = 0; j < writePos; j++) {
            trimmed[j] = compressed[j];
        }
        return trimmed;
    }

    /// @notice Decompresses RLE-encoded zero-byte calldata
    function decompress(bytes calldata compressed) external pure returns (bytes memory) {
        // First pass: determine uncompressed size
        uint256 totalLen = 0;
        uint256 cLen = compressed.length;
        uint256 i = 0;
        while (i < cLen) {
            if (compressed[i] == bytes1(ZERO_FLAG) && i + 1 < cLen) {
                totalLen += uint8(compressed[i + 1]);
                i += 2;
            } else {
                totalLen++;
                i++;
            }
        }

        bytes memory decompressed = new bytes(totalLen);
        uint256 writePos = 0;
        i = 0;
        while (i < cLen) {
            if (compressed[i] == bytes1(ZERO_FLAG) && i + 1 < cLen) {
                uint8 count = uint8(compressed[i + 1]);
                for (uint8 c = 0; c < count; c++) {
                    decompressed[writePos++] = 0x00;
                }
                i += 2;
            } else {
                decompressed[writePos++] = compressed[i];
                i++;
            }
        }

        return decompressed;
    }
}
