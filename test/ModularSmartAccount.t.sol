// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {ModularSmartAccount, UserOperation} from "../src/07_AccountAbstraction/ModularSmartAccount.sol";

contract MockRecipient {
    uint256 public received;

    receive() external payable {
        received += msg.value;
    }
}

contract ModularSmartAccountTest is Test {
    ModularSmartAccount public account;
    MockRecipient public recipient;

    address public entryPoint = address(0xEEEE);
    uint256 internal ownerKey = 0xAA11;
    address internal owner;

    function setUp() public {
        owner = vm.addr(ownerKey);
        account = new ModularSmartAccount{value: 5 ether}(entryPoint, owner);
        recipient = new MockRecipient();
    }

    function test_ValidateUserOpWithValidSignature() public {
        bytes32 opHash = keccak256("userOpHash");
        bytes32 ethHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", opHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerKey, ethHash);
        bytes memory sig = abi.encodePacked(r, s, v);

        UserOperation memory userOp;
        userOp.sender = address(account);
        userOp.signature = sig;

        vm.deal(entryPoint, 1 ether);

        // EntryPoint validates UserOp
        vm.prank(entryPoint);
        uint256 validationData = account.validateUserOp(userOp, opHash, 0.1 ether);

        assertEq(validationData, 0); // 0 = SIG_VALIDATION_SUCCESS
        assertEq(address(entryPoint).balance, 1.1 ether);
    }

    function test_ValidateUserOpWithInvalidSignatureFails() public {
        bytes32 opHash = keccak256("userOpHash");
        bytes32 ethHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", opHash));

        uint256 fakeKey = 0xBAD;
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(fakeKey, ethHash);
        bytes memory sig = abi.encodePacked(r, s, v);

        UserOperation memory userOp;
        userOp.sender = address(account);
        userOp.signature = sig;

        vm.prank(entryPoint);
        uint256 validationData = account.validateUserOp(userOp, opHash, 0);

        assertEq(validationData, 1); // 1 = SIG_VALIDATION_FAILED
    }

    function test_EntryPointExecutesOnBehalfOfAccount() public {
        vm.prank(entryPoint);
        account.execute(address(recipient), 1 ether, "");

        assertEq(recipient.received(), 1 ether);
    }
}
