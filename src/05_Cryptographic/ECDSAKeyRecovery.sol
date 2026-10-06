// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title ECDSAKeyRecovery
/// @notice Production-grade library for recovering ECDSA signers with strict malleability guards.
/// @dev Implements both standard 65-byte and EIP-2098 compact 64-byte signature recovery.
library ECDSAKeyRecovery {
    // --- Errors ---
    error InvalidSignatureLength();
    error InvalidSignatureS();
    error InvalidSignatureV();

    bytes32 private constant SECP256K1_N_DIV_2 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0;

    /// @notice Recover signer from a 32-byte digest and standard (r, s, v) signature
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return recover(hash, v, r, s);
        } else if (signature.length == 64) {
            // EIP-2098 compact signature (r, vs)
            bytes32 r;
            bytes32 vs;
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return recover(hash, r, vs);
        } else {
            revert InvalidSignatureLength();
        }
    }

    /// @notice Recover signer from standard (v, r, s) components
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        if (uint256(s) > uint256(SECP256K1_N_DIV_2)) revert InvalidSignatureS();
        if (v != 27 && v != 28) revert InvalidSignatureV();

        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) revert InvalidSignatureV();
        return signer;
    }

    /// @notice Recover signer from EIP-2098 compact (r, vs) components
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return recover(hash, v, r, s);
    }

    /// @notice Produce EIP-191 version 0x45 signed message hash
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}
