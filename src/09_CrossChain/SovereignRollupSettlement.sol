// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title SovereignRollupSettlement
/// @notice Fraud-proof dispute game settlement contract for optimistic sovereign rollups with interactive bisection.
contract SovereignRollupSettlement {
    // --- Errors ---
    error InsufficientBond();
    error ChallengePeriodExpired();
    error DisputeNotActive();
    error Unauthorized();
    error BatchAlreadyFinalized();

    // --- Events ---
    event BatchProposed(uint256 indexed batchId, address indexed proposer, bytes32 stateRoot, uint256 bond);
    event DisputeInitiated(uint256 indexed batchId, address indexed challenger);
    event DisputeSettled(uint256 indexed batchId, address indexed winner, address indexed loser, uint256 slashedBond);
    event BatchFinalized(uint256 indexed batchId, bytes32 finalizedStateRoot);

    enum Status {
        Proposed,
        Disputed,
        Finalized,
        Slashed
    }

    struct Batch {
        address proposer;
        bytes32 stateRoot;
        bytes32 traceRoot;
        uint256 bond;
        uint256 proposalTime;
        Status status;
        address challenger;
    }

    address public immutable adjudicator;
    uint256 public constant MIN_BOND = 1 ether;
    uint256 public constant CHALLENGE_WINDOW = 7 days;

    uint256 public nextBatchId = 1;
    mapping(uint256 => Batch) public batches;

    modifier onlyAdjudicator() {
        if (msg.sender != adjudicator) revert Unauthorized();
        _;
    }

    constructor(address _adjudicator) {
        adjudicator = _adjudicator;
    }

    function proposeBatch(bytes32 stateRoot, bytes32 traceRoot) external payable returns (uint256 batchId) {
        if (msg.value < MIN_BOND) revert InsufficientBond();

        batchId = nextBatchId++;
        batches[batchId] = Batch({
            proposer: msg.sender,
            stateRoot: stateRoot,
            traceRoot: traceRoot,
            bond: msg.value,
            proposalTime: block.timestamp,
            status: Status.Proposed,
            challenger: address(0)
        });

        emit BatchProposed(batchId, msg.sender, stateRoot, msg.value);
    }

    function challengeBatch(uint256 batchId) external payable {
        Batch storage b = batches[batchId];
        if (b.status != Status.Proposed) revert BatchAlreadyFinalized();
        if (block.timestamp > b.proposalTime + CHALLENGE_WINDOW) revert ChallengePeriodExpired();
        if (msg.value < b.bond) revert InsufficientBond();

        b.status = Status.Disputed;
        b.challenger = msg.sender;

        emit DisputeInitiated(batchId, msg.sender);
    }

    /// @notice Settle the interactive fraud proof game
    function settleDispute(uint256 batchId, bool proposerWon) external onlyAdjudicator {
        Batch storage b = batches[batchId];
        if (b.status != Status.Disputed) revert DisputeNotActive();

        if (proposerWon) {
            b.status = Status.Finalized;
            // Proposer wins challenger bond
            (bool pay,) = b.proposer.call{value: b.bond * 2}("");
            require(pay, "Reward failed");
            emit DisputeSettled(batchId, b.proposer, b.challenger, b.bond);
            emit BatchFinalized(batchId, b.stateRoot);
        } else {
            b.status = Status.Slashed;
            // Challenger wins proposer bond
            (bool pay,) = b.challenger.call{value: b.bond * 2}("");
            require(pay, "Reward failed");
            emit DisputeSettled(batchId, b.challenger, b.proposer, b.bond);
        }
    }

    function finalizeUnchallengedBatch(uint256 batchId) external {
        Batch storage b = batches[batchId];
        if (b.status != Status.Proposed) revert BatchAlreadyFinalized();
        if (block.timestamp <= b.proposalTime + CHALLENGE_WINDOW) revert ChallengePeriodExpired();

        b.status = Status.Finalized;
        // Refund proposer bond
        (bool refund,) = b.proposer.call{value: b.bond}("");
        require(refund, "Refund failed");

        emit BatchFinalized(batchId, b.stateRoot);
    }
}
