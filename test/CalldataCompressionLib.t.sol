// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {CalldataCompressionLib} from "../src/06_CancunEVM/CalldataCompressionLib.sol";

contract CalldataCompressionLibTest is Test {
    function test_CompressAndDecompress() public pure {
        // Create payload with many consecutive zeros
        bytes memory raw = abi.encode(uint256(42), uint256(100));

        bytes memory compressed = CalldataCompressionLib.compress(raw);
        // Compressed size should be substantially smaller than 64 bytes
        assertLt(compressed.length, raw.length);

        bytes memory decompressed = CalldataCompressionLib.decompress(compressed);
        assertEq(keccak256(decompressed), keccak256(raw));
    }
}
