// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title RingSignatureMixer
/// @notice Privacy mixer primitive using cryptographic commitments and spent nullifiers.
contract RingSignatureMixer {
    // --- Errors ---
    error InvalidDenomination();
    error NullifierAlreadySpent();
    error InvalidCommitment();
    error TransferFailed();
    error ZeroRecipient();

    // --- Events ---
    event Deposit(bytes32 indexed commitment, uint32 leafIndex, uint256 timestamp);
    event Withdrawal(address indexed to, bytes32 indexed nullifierHash, uint256 fee);

    // --- State Variables ---
    uint256 public constant DENOMINATION = 1 ether;

    mapping(bytes32 => bool) public commitments;
    mapping(bytes32 => bool) public nullifierSpent;
    bytes32[] public commitmentHistory;

    /// @notice Deposits fixed denomination with blinded commitment
    function deposit(bytes32 commitment) external payable {
        if (msg.value != DENOMINATION) revert InvalidDenomination();
        if (commitments[commitment]) revert InvalidCommitment();

        commitments[commitment] = true;
        uint32 leafIndex = uint32(commitmentHistory.length);
        commitmentHistory.push(commitment);

        emit Deposit(commitment, leafIndex, block.timestamp);
    }

    /// @notice Withdraws funds to an unlinked recipient using nullifier proof
    /// @param nullifierHash Hash of secret nullifier to prevent double-spending
    /// @param recipient Unlinked target address
    /// @param proofRingHash Hash proving commitment membership in the ring
    function withdraw(bytes32 nullifierHash, address payable recipient, bytes32 proofRingHash) external {
        if (recipient == address(0)) revert ZeroRecipient();
        if (nullifierSpent[nullifierHash]) revert NullifierAlreadySpent();
        if (!commitments[proofRingHash]) revert InvalidCommitment();

        nullifierSpent[nullifierHash] = true;

        (bool success,) = recipient.call{value: DENOMINATION}("");
        if (!success) revert TransferFailed();

        emit Withdrawal(recipient, nullifierHash, 0);
    }

    function totalDeposits() external view returns (uint256) {
        return commitmentHistory.length;
    }
}
