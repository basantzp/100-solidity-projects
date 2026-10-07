// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title OptimisticGovernor
/// @notice Optimistic governance module with bond requirements, challenge windows, and arbiter escalation.
contract OptimisticGovernor {
    // --- Errors ---
    error InsufficientBond();
    error ChallengeWindowActive();
    error ChallengeWindowExpired();
    error ProposalAlreadyResolved();
    error Unauthorized();
    error ActionExecutionFailed();

    // --- Events ---
    event ProposalAsserted(uint256 indexed id, bytes32 explanationHash, address target, bytes data, uint256 bond);
    event ProposalChallenged(uint256 indexed id, address indexed challenger, uint256 challengeBond);
    event ProposalExecuted(uint256 indexed id);
    event DisputeResolved(uint256 indexed id, bool approved);

    enum State {
        Asserted,
        Challenged,
        Executed,
        Rejected
    }

    struct Proposal {
        address asserter;
        address target;
        bytes data;
        uint256 bond;
        uint256 assertionTime;
        uint256 challengeDeadline;
        State state;
        address challenger;
    }

    address public immutable arbiter;
    uint256 public constant MIN_BOND = 1 ether;
    uint256 public constant LIVENESS_PERIOD = 3 days;

    uint256 public nextProposalId = 1;
    mapping(uint256 => Proposal) public proposals;

    modifier onlyArbiter() {
        if (msg.sender != arbiter) revert Unauthorized();
        _;
    }

    constructor(address _arbiter) {
        arbiter = _arbiter;
    }

    /// @notice Asserts a proposal optimistically by depositing bond
    function assertProposal(bytes32 explanationHash, address target, bytes calldata data)
        external
        payable
        returns (uint256 id)
    {
        if (msg.value < MIN_BOND) revert InsufficientBond();

        id = nextProposalId++;
        proposals[id] = Proposal({
            asserter: msg.sender,
            target: target,
            data: data,
            bond: msg.value,
            assertionTime: block.timestamp,
            challengeDeadline: block.timestamp + LIVENESS_PERIOD,
            state: State.Asserted,
            challenger: address(0)
        });

        emit ProposalAsserted(id, explanationHash, target, data, msg.value);
    }

    /// @notice Challenges an asserted proposal within the liveness window by posting matching bond
    function challengeProposal(uint256 id) external payable {
        Proposal storage prop = proposals[id];
        if (prop.state != State.Asserted) revert ProposalAlreadyResolved();
        if (block.timestamp > prop.challengeDeadline) revert ChallengeWindowExpired();
        if (msg.value < prop.bond) revert InsufficientBond();

        prop.state = State.Challenged;
        prop.challenger = msg.sender;

        emit ProposalChallenged(id, msg.sender, msg.value);
    }

    /// @notice Executes unchallenged proposal after liveness period passes
    function executeUnchallenged(uint256 id) external {
        Proposal storage prop = proposals[id];
        if (prop.state != State.Asserted) revert ProposalAlreadyResolved();
        if (block.timestamp <= prop.challengeDeadline) revert ChallengeWindowActive();

        prop.state = State.Executed;

        // Refund asserter bond
        (bool refund,) = prop.asserter.call{value: prop.bond}("");
        require(refund, "Refund failed");

        // Execute action
        (bool success,) = prop.target.call(prop.data);
        if (!success) revert ActionExecutionFailed();

        emit ProposalExecuted(id);
    }

    /// @notice Arbiter resolves a challenged proposal
    function resolveDispute(uint256 id, bool approve) external onlyArbiter {
        Proposal storage prop = proposals[id];
        if (prop.state != State.Challenged) revert ProposalAlreadyResolved();

        if (approve) {
            prop.state = State.Executed;
            // Asserter wins total bond (asserter bond + challenger bond)
            (bool payAsserter,) = prop.asserter.call{value: prop.bond * 2}("");
            require(payAsserter, "Reward failed");

            (bool success,) = prop.target.call(prop.data);
            if (!success) revert ActionExecutionFailed();
        } else {
            prop.state = State.Rejected;
            // Challenger wins total bond
            (bool payChallenger,) = prop.challenger.call{value: prop.bond * 2}("");
            require(payChallenger, "Reward failed");
        }

        emit DisputeResolved(id, approve);
    }
}
