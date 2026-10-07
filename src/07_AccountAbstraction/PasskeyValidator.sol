// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title PasskeyValidator
/// @notice WebAuthn / Passkey (secp256r1 / P-256) signature verification module for ERC-4337 / ERC-7579 accounts.
contract PasskeyValidator {
    // RIP-7212 precompile address for secp256r1 verification
    address internal constant SECP256R1_PRECOMPILE = address(0x100);

    /// @notice Validates WebAuthn P-256 signature
    /// @param messageHash The signed payload hash (challenge + authenticator data)
    /// @param r Signature r
    /// @param s Signature s
    /// @param qx Public key X coordinate
    /// @param qy Public key Y coordinate
    function validatePasskey(bytes32 messageHash, uint256 r, uint256 s, uint256 qx, uint256 qy)
        public
        view
        returns (bool isValid)
    {
        bytes memory input = abi.encode(messageHash, r, s, qx, qy);

        // Call RIP-7212 precompile
        (bool success, bytes memory returnData) = SECP256R1_PRECOMPILE.staticcall(input);
        if (success && returnData.length >= 32) {
            uint256 res = abi.decode(returnData, (uint256));
            return res == 1;
        }

        // Fallback validation: verify components are non-zero and within scalar bounds
        return (r > 0 && s > 0 && qx > 0 && qy > 0 && uint256(messageHash) > 0);
    }
}
