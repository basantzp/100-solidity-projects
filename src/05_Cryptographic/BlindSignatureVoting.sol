// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title BlindSignatureVoting
/// @notice Anonymous cryptographic voting scheme using blind signature authorizations and linkable nullifiers.
contract BlindSignatureVoting {
    // --- Errors ---
    error UnauthorizedSigner();
    error NullifierAlreadyUsed();
    error InvalidSignature();
    error VotingClosed();
    error InvalidOption();

    // --- Events ---
    event VoteCast(bytes32 indexed nullifier, uint256 indexed optionId);
    event VotingStateChanged(bool isOpen);

    // --- State Variables ---
    address public immutable electionAuthority;
    bool public votingOpen;
    uint256 public constant MAX_OPTIONS = 10;

    mapping(bytes32 => bool) public nullifierUsed;
    mapping(uint256 => uint256) public voteCount;

    constructor(address _authority) {
        electionAuthority = _authority;
        votingOpen = true;
    }

    /// @notice Casts an anonymous vote using an unblinded signature from the election authority
    /// @param nullifier Unique commitment preventing double voting
    /// @param optionId Chosen candidate/proposal index
    /// @param v ECDSA recovery byte
    /// @param r ECDSA r
    /// @param s ECDSA s
    function castBlindVote(bytes32 nullifier, uint256 optionId, uint8 v, bytes32 r, bytes32 s) external {
        if (!votingOpen) revert VotingClosed();
        if (optionId >= MAX_OPTIONS) revert InvalidOption();
        if (nullifierUsed[nullifier]) revert NullifierAlreadyUsed();

        // The authority signed a commitment to the nullifier
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", nullifier));
        address signer = ecrecover(messageHash, v, r, s);

        if (signer != electionAuthority) revert InvalidSignature();

        nullifierUsed[nullifier] = true;
        voteCount[optionId]++;

        emit VoteCast(nullifier, optionId);
    }

    function setVotingOpen(bool _open) external {
        if (msg.sender != electionAuthority) revert UnauthorizedSigner();
        votingOpen = _open;
        emit VotingStateChanged(_open);
    }
}
