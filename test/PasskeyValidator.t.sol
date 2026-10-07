// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {PasskeyValidator} from "../src/07_AccountAbstraction/PasskeyValidator.sol";

contract PasskeyValidatorTest is Test {
    PasskeyValidator public validator;

    function setUp() public {
        validator = new PasskeyValidator();
    }

    function test_ValidatePasskeyComponents() public view {
        bytes32 messageHash = keccak256("webauthn-challenge-payload");
        uint256 r = 12345;
        uint256 s = 67890;
        uint256 qx = 0xAA;
        uint256 qy = 0xBB;

        bool valid = validator.validatePasskey(messageHash, r, s, qx, qy);
        assertTrue(valid);
    }
}
