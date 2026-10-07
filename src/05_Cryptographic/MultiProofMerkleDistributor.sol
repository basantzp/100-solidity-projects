// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title MultiProofMerkleDistributor
/// @notice Batch Merkle multi-proof verification engine allowing multi-leaf verification in a single transaction.
contract MultiProofMerkleDistributor {
    // --- Errors ---
    error InvalidMultiProof();
    error AlreadyClaimed();
    error TransferFailed();
    error ArrayLengthMismatch();

    // --- Events ---
    event BatchClaimed(address indexed account, uint256 totalAmount, uint256 count);

    bytes32 public immutable merkleRoot;
    address public immutable token;

    // Bitmap for claimed indices: index / 256 => bitfield
    mapping(uint256 => uint256) private claimedBitmap;

    constructor(bytes32 _merkleRoot, address _token) {
        merkleRoot = _merkleRoot;
        token = _token;
    }

    function isClaimed(uint256 index) public view returns (bool) {
        uint256 wordIndex = index / 256;
        uint256 bitIndex = index % 256;
        uint256 word = claimedBitmap[wordIndex];
        return (word & (1 << bitIndex)) != 0;
    }

    function _setClaimed(uint256 index) internal {
        uint256 wordIndex = index / 256;
        uint256 bitIndex = index % 256;
        claimedBitmap[wordIndex] |= (1 << bitIndex);
    }

    /// @notice Verifies and processes batch claims using a Merkle multi-proof
    function claimMulti(
        uint256[] calldata indices,
        uint256[] calldata amounts,
        bytes32[] calldata proof,
        bool[] calldata proofFlags
    ) external returns (uint256 totalAmount) {
        if (indices.length != amounts.length) revert ArrayLengthMismatch();

        bytes32[] memory leaves = new bytes32[](indices.length);
        for (uint256 i = 0; i < indices.length; i++) {
            if (isClaimed(indices[i])) revert AlreadyClaimed();
            _setClaimed(indices[i]);

            leaves[i] = keccak256(abi.encodePacked(indices[i], msg.sender, amounts[i]));
            totalAmount += amounts[i];
        }

        // Reconstruct Merkle root from multi-proof
        bytes32 computedRoot = processMultiProof(proof, proofFlags, leaves);
        if (computedRoot != merkleRoot) revert InvalidMultiProof();

        // Safe transfer totalAmount to claimant
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSignature("transfer(address,uint256)", msg.sender, totalAmount));
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) revert TransferFailed();

        emit BatchClaimed(msg.sender, totalAmount, indices.length);
    }

    /// @notice Multi-proof verification logic
    function processMultiProof(bytes32[] calldata proof, bool[] calldata proofFlags, bytes32[] memory leaves)
        public
        pure
        returns (bytes32)
    {
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;
        bytes32[] memory targets = new bytes32[](leavesLen + totalHashes + proof.length + 1);

        for (uint256 i = 0; i < leavesLen; i++) {
            targets[i] = leaves[i];
        }

        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;

        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a =
                leafPos < targets.length && targets[leafPos] != bytes32(0) ? targets[leafPos++] : proof[proofPos++];

            bytes32 b = proofFlags[i]
                ? (leafPos < targets.length && targets[leafPos] != bytes32(0) ? targets[leafPos++] : proof[proofPos++])
                : proof[proofPos++];

            targets[leavesLen + hashPos++] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return targets[leavesLen + totalHashes - 1];
        } else if (leavesLen > 0) {
            return targets[0];
        } else {
            return proof.length > 0 ? proof[0] : bytes32(0);
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? keccak256(abi.encodePacked(a, b)) : keccak256(abi.encodePacked(b, a));
    }
}
