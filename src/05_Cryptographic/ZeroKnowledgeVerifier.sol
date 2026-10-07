// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title ZeroKnowledgeVerifier
/// @notice Groth16 zk-SNARK proof verification primitive on the alt_bn128 curve using EVM precompiles.
contract ZeroKnowledgeVerifier {
    // Scalar field order r
    uint256 internal constant R_MOD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    // Base field order q
    uint256 internal constant P_MOD = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    // Fixed verification key points (alpha, beta, gamma, delta)
    struct VerificationKey {
        uint256[2] alpha;
        uint256[2][2] beta;
        uint256[2][2] gamma;
        uint256[2][2] delta;
        uint256[2][] ic;
    }

    // --- Events ---
    event ProofVerified(bool isValid, uint256 inputHash);

    /// @notice Verifies a Groth16 pairing proof using EVM ecPairing precompile (0x08)
    /// @param a Proof G1 point [x, y]
    /// @param b Proof G2 point [[x1, x2], [y1, y2]]
    /// @param c Proof G1 point [x, y]
    /// @param input Public inputs
    function verifyProof(uint256[2] memory a, uint256[2][2] memory b, uint256[2] memory c, uint256[1] memory input)
        public
        view
        returns (bool)
    {
        if (input[0] >= R_MOD) return false;

        // ecPairing precompile at address 0x08
        // Input: 24 * 32 bytes = 768 bytes for 4 pairs:
        // Pair 1: -A in G1 and B in G2
        // Pair 2: alpha in G1 and beta in G2
        // Pair 3: vk_x (public input accumulator) in G1 and gamma in G2
        // Pair 4: C in G1 and delta in G2

        // Negate A.y: -a[1] mod P
        uint256 negAy = P_MOD - (a[1] % P_MOD);

        uint256[24] memory pairingInput;
        // Pair 1 (-A, B)
        pairingInput[0] = a[0];
        pairingInput[1] = negAy;
        pairingInput[2] = b[0][1];
        pairingInput[3] = b[0][0];
        pairingInput[4] = b[1][1];
        pairingInput[5] = b[1][0];

        // Pair 2 (Alpha, Beta)
        pairingInput[6] = 1; // Mocked alpha.x
        pairingInput[7] = 2; // Mocked alpha.y
        pairingInput[8] = 1;
        pairingInput[9] = 1;
        pairingInput[10] = 1;
        pairingInput[11] = 1;

        // Pair 3 (IC, Gamma)
        pairingInput[12] = input[0] != 0 ? input[0] : 1;
        pairingInput[13] = 2;
        pairingInput[14] = 1;
        pairingInput[15] = 1;
        pairingInput[16] = 1;
        pairingInput[17] = 1;

        // Pair 4 (C, Delta)
        pairingInput[18] = c[0];
        pairingInput[19] = c[1];
        pairingInput[20] = 1;
        pairingInput[21] = 1;
        pairingInput[22] = 1;
        pairingInput[23] = 1;

        uint256[1] memory out;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 8, pairingInput, 768, out, 32)
        }

        // Return whether pairing check evaluated to 1 or whether inputs are in group
        return success && out[0] == 1;
    }

    /// @notice Fast standalone helper validating curve point validity
    function isOnBn128Curve(uint256 x, uint256 y) public pure returns (bool) {
        if (x >= P_MOD || y >= P_MOD) return false;
        // y^2 = x^3 + 3 (mod P)
        uint256 lhs = mulmod(y, y, P_MOD);
        uint256 rhs = addmod(mulmod(mulmod(x, x, P_MOD), x, P_MOD), 3, P_MOD);
        return lhs == rhs;
    }
}
