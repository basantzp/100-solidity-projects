// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {BlindSignatureVoting} from "../src/05_Cryptographic/BlindSignatureVoting.sol";

contract BlindSignatureVotingTest is Test {
    BlindSignatureVoting public voting;
    uint256 internal authorityPrivateKey = 0xA11CE;
    address internal authority;

    function setUp() public {
        authority = vm.addr(authorityPrivateKey);
        voting = new BlindSignatureVoting(authority);
    }

    function test_CastValidBlindVote() public {
        bytes32 nullifier = keccak256(abi.encodePacked("voter-secret-ticket-1"));

        // Authority signs commitment to the nullifier
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", nullifier));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(authorityPrivateKey, messageHash);

        // Voter submits vote anonymously with the unblinded signature
        voting.castBlindVote(nullifier, 1, v, r, s);

        assertEq(voting.voteCount(1), 1);
        assertTrue(voting.nullifierUsed(nullifier));

        // Re-voting with same nullifier reverts
        vm.expectRevert(BlindSignatureVoting.NullifierAlreadyUsed.selector);
        voting.castBlindVote(nullifier, 1, v, r, s);
    }

    function test_InvalidSignatureReverts() public {
        bytes32 nullifier = keccak256(abi.encodePacked("fake-ticket"));
        uint256 fakeKey = 0xBAD;
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", nullifier));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(fakeKey, messageHash);

        vm.expectRevert(BlindSignatureVoting.InvalidSignature.selector);
        voting.castBlindVote(nullifier, 0, v, r, s);
    }
}
