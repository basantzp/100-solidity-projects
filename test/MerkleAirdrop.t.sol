// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {MerkleAirdrop} from "../src/05_Cryptographic/MerkleAirdrop.sol";
import {ERC20Permit} from "../src/01_Tokens/ERC20Permit.sol";

contract MockRewardToken is ERC20Permit {
    constructor() ERC20Permit("Reward", "RWD", 18) {
        _mint(msg.sender, 1_000_000e18);
    }
}

contract MerkleAirdropTest is Test {
    MockRewardToken token;
    MerkleAirdrop airdrop;

    address alice = address(0x1);
    address bob = address(0x2);

    uint256 amountAlice = 100e18;
    uint256 amountBob = 200e18;

    bytes32 leafAlice;
    bytes32 leafBob;
    bytes32 merkleRoot;

    function setUp() public {
        token = new MockRewardToken();

        // 2-leaf Merkle Tree:
        // leaf0 = keccak256(bytes.concat(keccak256(abi.encode(0, alice, amountAlice))))
        // leaf1 = keccak256(bytes.concat(keccak256(abi.encode(1, bob, amountBob))))
        leafAlice = keccak256(bytes.concat(keccak256(abi.encode(uint256(0), alice, amountAlice))));
        leafBob = keccak256(bytes.concat(keccak256(abi.encode(uint256(1), bob, amountBob))));

        if (leafAlice <= leafBob) {
            merkleRoot = keccak256(abi.encodePacked(leafAlice, leafBob));
        } else {
            merkleRoot = keccak256(abi.encodePacked(leafBob, leafAlice));
        }

        airdrop = new MerkleAirdrop(address(token), merkleRoot);

        // Fund airdrop contract
        token.transfer(address(airdrop), 10_000e18);
    }

    function test_AliceCanClaimWithProof() public {
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = leafBob;

        assertFalse(airdrop.isClaimed(0));

        vm.prank(alice);
        airdrop.claim(0, alice, amountAlice, proof);

        assertTrue(airdrop.isClaimed(0));
        assertEq(token.balanceOf(alice), amountAlice);
    }

    function test_CannotClaimTwice() public {
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = leafBob;

        airdrop.claim(0, alice, amountAlice, proof);

        vm.expectRevert(abi.encodeWithSelector(MerkleAirdrop.AlreadyClaimed.selector, 0));
        airdrop.claim(0, alice, amountAlice, proof);
    }

    function test_RevertIf_InvalidProof() public {
        bytes32[] memory fakeProof = new bytes32[](1);
        fakeProof[0] = bytes32(uint256(0xdeadbeef));

        vm.expectRevert(MerkleAirdrop.InvalidMerkleProof.selector);
        airdrop.claim(0, alice, amountAlice, fakeProof);
    }
}
