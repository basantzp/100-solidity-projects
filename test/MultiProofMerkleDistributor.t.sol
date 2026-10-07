// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {MultiProofMerkleDistributor} from "../src/05_Cryptographic/MultiProofMerkleDistributor.sol";
import {ERC20Votes} from "../src/01_Tokens/ERC20Votes.sol";

contract MultiProofMerkleDistributorTest is Test {
    MultiProofMerkleDistributor public distributor;
    ERC20Votes public token;

    address public alice = address(0xA11CE);

    function setUp() public {
        token = new ERC20Votes("Reward Token", "RWD");

        // Simple two-leaf tree
        // Leaf 0: (index 0, alice, 100e18)
        // Leaf 1: (index 1, alice, 200e18)
        bytes32 leaf0 = keccak256(abi.encodePacked(uint256(0), alice, uint256(100e18)));
        bytes32 leaf1 = keccak256(abi.encodePacked(uint256(1), alice, uint256(200e18)));

        bytes32 root =
            leaf0 < leaf1 ? keccak256(abi.encodePacked(leaf0, leaf1)) : keccak256(abi.encodePacked(leaf1, leaf0));

        distributor = new MultiProofMerkleDistributor(root, address(token));
        token.mint(address(distributor), 10_000e18);
    }

    function test_MultiClaim() public {
        uint256[] memory indices = new uint256[](2);
        indices[0] = 0;
        indices[1] = 1;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100e18;
        amounts[1] = 200e18;

        bytes32[] memory proof = new bytes32[](0);
        bool[] memory proofFlags = new bool[](1);
        proofFlags[0] = true;

        vm.prank(alice);
        uint256 total = distributor.claimMulti(indices, amounts, proof, proofFlags);

        assertEq(total, 300e18);
        assertEq(token.balanceOf(alice), 300e18);
        assertTrue(distributor.isClaimed(0));
        assertTrue(distributor.isClaimed(1));

        // Re-claiming reverts
        vm.prank(alice);
        vm.expectRevert(MultiProofMerkleDistributor.AlreadyClaimed.selector);
        distributor.claimMulti(indices, amounts, proof, proofFlags);
    }
}
