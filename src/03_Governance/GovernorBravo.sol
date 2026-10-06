// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface IVotes {
    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);
    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);
}

/// @title GovernorBravo
/// @notice Comprehensive DAO governance proposal lifecycle and quorum voting engine.
contract GovernorBravo {
    // --- Errors ---
    error InvalidProposalState();
    error ProposalAlreadyExists();
    error QuorumNotMet();
    error VotingPeriodActive();
    error AlreadyVoted();
    error ExecutionFailed();
    error ZeroAddress();

    // --- Enums ---
    enum ProposalState {
        Pending,
        Active,
        Defeated,
        Succeeded,
        Executed,
        Canceled
    }

    // --- Structs ---
    struct Proposal {
        uint256 id;
        address proposer;
        address target;
        bytes data;
        uint256 startBlock;
        uint256 endBlock;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        bool executed;
        bool canceled;
    }

    // --- State Variables ---
    IVotes public immutable token;
    uint256 public immutable votingDelay; // in blocks
    uint256 public immutable votingPeriod; // in blocks
    uint256 public immutable quorumNumerator; // e.g. 4 for 4%

    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    event ProposalCreated(
        uint256 indexed id, address indexed proposer, address target, uint256 startBlock, uint256 endBlock
    );
    event VoteCast(address indexed voter, uint256 indexed proposalId, uint8 support, uint256 weight);
    event ProposalExecuted(uint256 indexed id);

    constructor(IVotes _token, uint256 _votingDelay, uint256 _votingPeriod, uint256 _quorumNumerator) {
        token = _token;
        votingDelay = _votingDelay;
        votingPeriod = _votingPeriod;
        quorumNumerator = _quorumNumerator;
    }

    function propose(address target, bytes calldata data) external returns (uint256 proposalId) {
        proposalId = ++proposalCount;

        uint256 startBlock = block.number + votingDelay;
        uint256 endBlock = startBlock + votingPeriod;

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            target: target,
            data: data,
            startBlock: startBlock,
            endBlock: endBlock,
            forVotes: 0,
            againstVotes: 0,
            abstainVotes: 0,
            executed: false,
            canceled: false
        });

        emit ProposalCreated(proposalId, msg.sender, target, startBlock, endBlock);
    }

    function castVote(uint256 proposalId, uint8 support) external returns (uint256 weight) {
        if (state(proposalId) != ProposalState.Active) revert InvalidProposalState();
        if (hasVoted[proposalId][msg.sender]) revert AlreadyVoted();

        Proposal storage p = proposals[proposalId];
        weight = token.getPastVotes(msg.sender, p.startBlock);

        hasVoted[proposalId][msg.sender] = true;

        if (support == 0) {
            p.againstVotes += weight;
        } else if (support == 1) {
            p.forVotes += weight;
        } else if (support == 2) {
            p.abstainVotes += weight;
        }

        emit VoteCast(msg.sender, proposalId, support, weight);
    }

    function execute(uint256 proposalId) external returns (bytes memory) {
        if (state(proposalId) != ProposalState.Succeeded) revert InvalidProposalState();

        Proposal storage p = proposals[proposalId];
        p.executed = true;

        (bool success, bytes memory result) = p.target.call(p.data);
        if (!success) revert ExecutionFailed();

        emit ProposalExecuted(proposalId);
        return result;
    }

    function state(uint256 proposalId) public view returns (ProposalState) {
        Proposal storage p = proposals[proposalId];
        if (p.executed) return ProposalState.Executed;
        if (p.canceled) return ProposalState.Canceled;
        if (block.number <= p.startBlock) return ProposalState.Pending;
        if (block.number <= p.endBlock) return ProposalState.Active;

        uint256 pastSupply = token.getPastTotalSupply(p.startBlock);
        uint256 quorum = (pastSupply * quorumNumerator) / 100;

        if (p.forVotes + p.abstainVotes < quorum) return ProposalState.Defeated;
        if (p.forVotes <= p.againstVotes) return ProposalState.Defeated;

        return ProposalState.Succeeded;
    }
}
