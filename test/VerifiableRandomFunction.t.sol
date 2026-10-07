// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {VerifiableRandomFunction} from "../src/05_Cryptographic/VerifiableRandomFunction.sol";

contract VerifiableRandomFunctionTest is Test {
    VerifiableRandomFunction public vrf;
    uint256 internal coordinatorKey = 0xC001D;
    address internal coordinator;

    address public user = address(0xCAFE);

    function setUp() public {
        coordinator = vm.addr(coordinatorKey);
        vrf = new VerifiableRandomFunction(coordinator);
    }

    function test_RequestAndFulfillRandomness() public {
        vm.prank(user);
        uint256 requestId = vrf.requestRandomness(123456789);
        assertEq(requestId, 1);

        uint256 generatedRandomness = 777888999;

        // Coordinator signs proof
        bytes32 proofHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encode(requestId, uint256(123456789), generatedRandomness))
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(coordinatorKey, proofHash);

        // Fulfill randomness
        vrf.fulfillRandomness(requestId, generatedRandomness, v, r, s);

        assertEq(vrf.getRandomWord(requestId), generatedRandomness);

        // Fulfilling again reverts
        vm.expectRevert(VerifiableRandomFunction.RequestAlreadyFulfilled.selector);
        vrf.fulfillRandomness(requestId, generatedRandomness, v, r, s);
    }
}
