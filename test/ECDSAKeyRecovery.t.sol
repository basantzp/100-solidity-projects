// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {ECDSAKeyRecovery} from "../src/05_Cryptographic/ECDSAKeyRecovery.sol";

contract ECDSAKeyRecoveryConsumer {
    function recoverStandard(bytes32 hash, bytes memory signature) external pure returns (address) {
        return ECDSAKeyRecovery.recover(hash, signature);
    }

    function recoverCompact(bytes32 hash, bytes32 r, bytes32 vs) external pure returns (address) {
        return ECDSAKeyRecovery.recover(hash, r, vs);
    }
}

contract ECDSAKeyRecoveryTest is Test {
    ECDSAKeyRecoveryConsumer public consumer;
    uint256 internal privateKey = 0xABCD1234;
    address internal expectedSigner;

    function setUp() public {
        consumer = new ECDSAKeyRecoveryConsumer();
        expectedSigner = vm.addr(privateKey);
    }

    function test_RecoverStandardSignature() public {
        bytes32 messageHash = keccak256(abi.encodePacked("Hello Antigravity"));
        bytes32 ethSignedHash = ECDSAKeyRecovery.toEthSignedMessageHash(messageHash);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, ethSignedHash);
        bytes memory sig = abi.encodePacked(r, s, v);

        address recovered = consumer.recoverStandard(ethSignedHash, sig);
        assertEq(recovered, expectedSigner);
    }

    function test_RecoverCompactEIP2098Signature() public {
        bytes32 messageHash = keccak256(abi.encodePacked("Compact EIP-2098"));
        bytes32 ethSignedHash = ECDSAKeyRecovery.toEthSignedMessageHash(messageHash);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, ethSignedHash);

        // Convert (v, s) to compact vs
        uint256 vBit = (v == 28) ? (1 << 255) : 0;
        bytes32 vs = bytes32(uint256(s) | vBit);

        address recovered = consumer.recoverCompact(ethSignedHash, r, vs);
        assertEq(recovered, expectedSigner);
    }

    function test_RevertIf_MalleableHighS() public {
        bytes32 hash = keccak256("test");
        bytes32 r = bytes32(uint256(1));
        // High s beyond n/2
        bytes32 highS = bytes32(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364140);
        uint8 v = 27;
        bytes memory sig = abi.encodePacked(r, highS, v);

        vm.expectRevert(ECDSAKeyRecovery.InvalidSignatureS.selector);
        consumer.recoverStandard(hash, sig);
    }
}
