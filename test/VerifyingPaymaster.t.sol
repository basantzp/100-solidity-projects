// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {VerifyingPaymaster} from "../src/07_AccountAbstraction/VerifyingPaymaster.sol";
import {UserOperation} from "../src/07_AccountAbstraction/ModularSmartAccount.sol";

contract VerifyingPaymasterTest is Test {
    VerifyingPaymaster public paymaster;
    address public entryPoint = address(0xEEEE);

    uint256 internal signerPrivateKey = 0x5164;
    address internal verifyingSigner;

    function setUp() public {
        verifyingSigner = vm.addr(signerPrivateKey);
        paymaster = new VerifyingPaymaster(entryPoint, verifyingSigner);
    }

    function test_ValidatePaymasterUserOpSuccess() public {
        bytes32 userOpHash = keccak256("userOpHash");
        uint48 validUntil = uint48(block.timestamp + 1000);
        uint48 validAfter = uint48(block.timestamp);

        bytes32 hash = paymaster.getHash(userOpHash, validUntil, validAfter);
        bytes32 ethHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, ethHash);
        bytes memory sig = abi.encodePacked(r, s, v);

        bytes memory paymasterAndData =
            abi.encodePacked(address(paymaster), bytes6(validUntil), bytes6(validAfter), sig);

        UserOperation memory userOp;
        userOp.sender = address(0x123);
        userOp.paymasterAndData = paymasterAndData;

        vm.prank(entryPoint);
        (bytes memory context, uint256 validationData) = paymaster.validatePaymasterUserOp(userOp, userOpHash, 1 ether);

        // Validation succeeded (least significant 160 bits is 0)
        assertEq(uint160(validationData), 0);
        assertGt(context.length, 0);
    }

    function test_InvalidSignerFails() public {
        bytes32 userOpHash = keccak256("userOpHash");
        uint48 validUntil = uint48(block.timestamp + 1000);
        uint48 validAfter = uint48(block.timestamp);

        bytes32 hash = paymaster.getHash(userOpHash, validUntil, validAfter);
        bytes32 ethHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));

        uint256 fakeKey = 0x999;
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(fakeKey, ethHash);
        bytes memory sig = abi.encodePacked(r, s, v);

        bytes memory paymasterAndData =
            abi.encodePacked(address(paymaster), bytes6(validUntil), bytes6(validAfter), sig);

        UserOperation memory userOp;
        userOp.sender = address(0x123);
        userOp.paymasterAndData = paymasterAndData;

        vm.prank(entryPoint);
        (, uint256 validationData) = paymaster.validatePaymasterUserOp(userOp, userOpHash, 1 ether);

        // 1 = SIG_VALIDATION_FAILED
        assertEq(validationData, 1);
    }
}
