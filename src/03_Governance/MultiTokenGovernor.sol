// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title MultiTokenGovernor
/// @notice Dual-governance engine requiring approval from both Capital and Community tokens, with veto protections.
contract MultiTokenGovernor {
    // --- Errors ---
    error AlreadyVoted();
    error VotingClosed();
    error VotingStillActive();
    error QuorumNotReached();
    error CommunityVetoTriggered();
    error ProposalAlreadyExecuted();
    error ZeroVotingPower();

    // --- Events ---
    event ProposalCreated(uint256 indexed id, string description, uint256 deadline);
    event VoteCast(uint256 indexed id, address indexed voter, bool isCapitalToken, bool support, uint256 weight);
    event ProposalExecuted(uint256 indexed id);

    struct Proposal {
        string description;
        uint256 deadline;
        uint256 capitalVotesFor;
        uint256 capitalVotesAgainst;
        uint256 communityVotesFor;
        uint256 communityVotesAgainst;
        bool executed;
    }

    address public immutable capitalToken;
    address public immutable communityToken;

    uint256 public constant VOTING_PERIOD = 3 days;
    uint256 public constant CAPITAL_QUORUM = 100e18;
    uint256 public constant COMMUNITY_QUORUM = 10e18;

    uint256 public nextProposalId = 1;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVotedCapital;
    mapping(uint256 => mapping(address => bool)) public hasVotedCommunity;

    constructor(address _capitalToken, address _communityToken) {
        capitalToken = _capitalToken;
        communityToken = _communityToken;
    }

    function propose(string memory description) external returns (uint256 id) {
        id = nextProposalId++;
        proposals[id] = Proposal({
            description: description,
            deadline: block.timestamp + VOTING_PERIOD,
            capitalVotesFor: 0,
            capitalVotesAgainst: 0,
            communityVotesFor: 0,
            communityVotesAgainst: 0,
            executed: false
        });

        emit ProposalCreated(id, description, block.timestamp + VOTING_PERIOD);
    }

    function voteWithCapital(uint256 id, bool support) external {
        Proposal storage p = proposals[id];
        if (block.timestamp > p.deadline) revert VotingClosed();
        if (hasVotedCapital[id][msg.sender]) revert AlreadyVoted();

        uint256 weight = _getBalance(capitalToken, msg.sender);
        if (weight == 0) revert ZeroVotingPower();

        hasVotedCapital[id][msg.sender] = true;
        if (support) {
            p.capitalVotesFor += weight;
        } else {
            p.capitalVotesAgainst += weight;
        }

        emit VoteCast(id, msg.sender, true, support, weight);
    }

    function voteWithCommunity(uint256 id, bool support) external {
        Proposal storage p = proposals[id];
        if (block.timestamp > p.deadline) revert VotingClosed();
        if (hasVotedCommunity[id][msg.sender]) revert AlreadyVoted();

        uint256 weight = _getBalance(communityToken, msg.sender);
        if (weight == 0) revert ZeroVotingPower();

        hasVotedCommunity[id][msg.sender] = true;
        if (support) {
            p.communityVotesFor += weight;
        } else {
            p.communityVotesAgainst += weight;
        }

        emit VoteCast(id, msg.sender, false, support, weight);
    }

    function execute(uint256 id) external {
        Proposal storage p = proposals[id];
        if (block.timestamp <= p.deadline) revert VotingStillActive();
        if (p.executed) revert ProposalAlreadyExecuted();

        // Capital quorum check
        uint256 totalCapital = p.capitalVotesFor + p.capitalVotesAgainst;
        if (totalCapital < CAPITAL_QUORUM || p.capitalVotesFor <= p.capitalVotesAgainst) {
            revert QuorumNotReached();
        }

        // Community Veto Check: If community quorum met and > 50% against, veto!
        uint256 totalCommunity = p.communityVotesFor + p.communityVotesAgainst;
        if (totalCommunity >= COMMUNITY_QUORUM && p.communityVotesAgainst >= p.communityVotesFor) {
            revert CommunityVetoTriggered();
        }

        p.executed = true;
        emit ProposalExecuted(id);
    }

    function _getBalance(address token, address account) internal view returns (uint256) {
        (bool success, bytes memory data) = token.staticcall(abi.encodeWithSignature("balanceOf(address)", account));
        if (success && data.length >= 32) {
            return abi.decode(data, (uint256));
        }
        return 0;
    }
}
