// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title QuadraticVotingEngine
/// @notice Sybil-resilient quadratic voting aggregator where credit cost scales quadratically with vote weight.
/// @dev Cost = votes^2. Prevents whale domination by amplifying preference distribution across proposals.
contract QuadraticVotingEngine {
    // --- Errors ---
    error InsufficientVoiceCredits();
    error PollClosed();
    error PollNotEnded();
    error InvalidProposal();
    error Unauthorized();

    // --- Structs ---
    struct Poll {
        string description;
        uint256 endTime;
        uint256 proposalCount;
        bool closed;
    }

    uint256 public nextPollId;
    address public admin;

    mapping(uint256 => Poll) public polls;
    mapping(uint256 => mapping(uint256 => uint256)) public proposalVotes; // pollId => proposalId => votes
    mapping(uint256 => mapping(address => uint256)) public voiceCredits; // pollId => voter => credits
    mapping(uint256 => mapping(address => mapping(uint256 => uint256))) public votesCast; // pollId => voter => propId => votes

    event PollCreated(uint256 indexed pollId, string description, uint256 proposalCount, uint256 endTime);
    event CreditsRegistered(uint256 indexed pollId, address indexed voter, uint256 credits);
    event VoteCast(
        uint256 indexed pollId, address indexed voter, uint256 indexed proposalId, uint256 votes, uint256 cost
    );

    modifier onlyAdmin() {
        if (msg.sender != admin) revert Unauthorized();
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function createPoll(string calldata description, uint256 proposalCount, uint256 duration)
        external
        onlyAdmin
        returns (uint256 pollId)
    {
        pollId = nextPollId++;
        polls[pollId] = Poll({
            description: description, endTime: block.timestamp + duration, proposalCount: proposalCount, closed: false
        });

        emit PollCreated(pollId, description, proposalCount, polls[pollId].endTime);
    }

    function registerVoter(uint256 pollId, address voter, uint256 credits) external onlyAdmin {
        voiceCredits[pollId][voter] += credits;
        emit CreditsRegistered(pollId, voter, credits);
    }

    /// @notice Cast quadratic votes for a proposal (cost = newVotes^2 - oldVotes^2)
    function vote(uint256 pollId, uint256 proposalId, uint256 newVoteCount) external {
        Poll storage p = polls[pollId];
        if (block.timestamp > p.endTime || p.closed) revert PollClosed();
        if (proposalId >= p.proposalCount) revert InvalidProposal();

        uint256 prevVotes = votesCast[pollId][msg.sender][proposalId];
        uint256 prevCost = prevVotes * prevVotes;
        uint256 newCost = newVoteCount * newVoteCount;

        if (newCost > prevCost) {
            uint256 additionalCost = newCost - prevCost;
            if (voiceCredits[pollId][msg.sender] < additionalCost) revert InsufficientVoiceCredits();
            voiceCredits[pollId][msg.sender] -= additionalCost;
            proposalVotes[pollId][proposalId] += (newVoteCount - prevVotes);
        } else {
            uint256 refund = prevCost - newCost;
            voiceCredits[pollId][msg.sender] += refund;
            proposalVotes[pollId][proposalId] -= (prevVotes - newVoteCount);
        }

        votesCast[pollId][msg.sender][proposalId] = newVoteCount;
        emit VoteCast(pollId, msg.sender, proposalId, newVoteCount, newCost);
    }
}
