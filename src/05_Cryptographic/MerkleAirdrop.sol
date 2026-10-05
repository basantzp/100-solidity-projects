// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20Permit} from "../01_Tokens/ERC20Permit.sol";

/// @title MerkleAirdrop
/// @notice Gas-optimized cryptographic token distribution using Merkle trees and 256-bit bitmap claim tracking
contract MerkleAirdrop {
    /* -------------------------------------------------------------------------- */
    /*                                   ERRORS                                   */
    /* -------------------------------------------------------------------------- */
    error AlreadyClaimed(uint256 index);
    error InvalidMerkleProof();
    error TransferFailed();

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */
    event Claimed(uint256 indexed index, address indexed account, uint256 amount);

    /* -------------------------------------------------------------------------- */
    /*                                    STATE                                   */
    /* -------------------------------------------------------------------------- */
    address public immutable token;
    bytes32 public immutable merkleRoot;

    // Packed bitmap: wordIndex => 256 bits of claimed status
    mapping(uint256 => uint256) private claimedBitMap;

    constructor(address _token, bytes32 _merkleRoot) {
        token = _token;
        merkleRoot = _merkleRoot;
    }

    /// @notice Returns true if index has already been claimed
    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    /// @notice Claims airdrop rewards with Merkle proof
    /// @param index Leaf index in the distribution tree
    /// @param account Recipient address
    /// @param amount Token quantity allocated
    /// @param merkleProof Inclusion proof from leaf to root
    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external {
        if (isClaimed(index)) revert AlreadyClaimed(index);

        // Verify leaf hash: keccak256(bytes.concat(keccak256(abi.encode(index, account, amount))))
        bytes32 node = keccak256(bytes.concat(keccak256(abi.encode(index, account, amount))));
        if (!verifyProof(merkleProof, merkleRoot, node)) revert InvalidMerkleProof();

        _setClaimed(index);

        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(ERC20Permit.transfer.selector, account, amount));
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) revert TransferFailed();

        emit Claimed(index, account, amount);
    }

    /// @notice Verifies a cryptographic Merkle proof against a root
    function verifyProof(bytes32[] memory proof, bytes32 root, bytes32 leaf) public pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        return computedHash == root;
    }
}
