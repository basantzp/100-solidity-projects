// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {ZeroKnowledgeVerifier} from "../src/05_Cryptographic/ZeroKnowledgeVerifier.sol";

contract ZeroKnowledgeVerifierTest is Test {
    ZeroKnowledgeVerifier public verifier;

    function setUp() public {
        verifier = new ZeroKnowledgeVerifier();
    }

    function test_CurveValidation() public view {
        // Generator point for bn128: (1, 2)
        // 2^2 = 4; 1^3 + 3 = 4 (mod P)
        assertTrue(verifier.isOnBn128Curve(1, 2));

        // Invalid point
        assertFalse(verifier.isOnBn128Curve(1, 5));
    }

    function test_VerifyProofRejectsInvalidScalarInput() public view {
        uint256[2] memory a = [uint256(1), uint256(2)];
        uint256[2][2] memory b = [[uint256(1), uint256(1)], [uint256(1), uint256(1)]];
        uint256[2] memory c = [uint256(1), uint256(2)];

        // Input exceeding R_MOD scalar modulus
        uint256[1] memory invalidInput = [type(uint256).max];
        assertFalse(verifier.verifyProof(a, b, c, invalidInput));
    }
}
