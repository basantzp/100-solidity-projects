// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title CommitReveal
/// @notice MEV-resistant commit-reveal cryptographic voting/randomness scheme
contract CommitReveal {
    event Committed(address indexed user, bytes32 commitment);
    event Revealed(address indexed user, uint256 choice);

    error CommitPhaseEnded();
    error RevealPhaseNotStarted();
    error RevealPhaseEnded();
    error AlreadyCommitted();
    error HashMismatch();
    error NotCommitted();

    uint256 public immutable commitDeadline;
    uint256 public immutable revealDeadline;

    mapping(address => bytes32) public commitments;
    mapping(address => uint256) public revealedVotes;
    mapping(address => bool) public hasRevealed;

    uint256 public totalVotesForOption1;
    uint256 public totalVotesForOption2;

    constructor(uint256 _commitDuration, uint256 _revealDuration) {
        commitDeadline = block.timestamp + _commitDuration;
        revealDeadline = block.timestamp + _commitDuration + _revealDuration;
    }

    function commit(bytes32 _commitment) external {
        if (block.timestamp >= commitDeadline) revert CommitPhaseEnded();
        if (commitments[msg.sender] != bytes32(0)) revert AlreadyCommitted();

        commitments[msg.sender] = _commitment;
        emit Committed(msg.sender, _commitment);
    }

    function reveal(uint256 choice, bytes32 secret) external {
        if (block.timestamp < commitDeadline) revert RevealPhaseNotStarted();
        if (block.timestamp >= revealDeadline) revert RevealPhaseEnded();
        if (commitments[msg.sender] == bytes32(0)) revert NotCommitted();
        if (hasRevealed[msg.sender]) revert AlreadyCommitted();

        bytes32 expectedHash = keccak256(abi.encodePacked(choice, secret, msg.sender));
        if (expectedHash != commitments[msg.sender]) revert HashMismatch();

        hasRevealed[msg.sender] = true;
        revealedVotes[msg.sender] = choice;

        if (choice == 1) {
            totalVotesForOption1++;
        } else if (choice == 2) {
            totalVotesForOption2++;
        }

        emit Revealed(msg.sender, choice);
    }

    function getSaltedHash(uint256 choice, bytes32 secret, address sender) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(choice, secret, sender));
    }
}
