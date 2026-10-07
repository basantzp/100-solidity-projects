// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title ConvictionVoting
/// @notice Continuous conviction voting engine where conviction accumulates continuously over time according to staked tokens.
contract ConvictionVoting {
    // --- Errors ---
    error InsufficientStaked();
    error ThresholdNotMet();
    error ProposalAlreadyPassed();
    error TransferFailed();
    error ZeroAmount();

    // --- Events ---
    event ProposalCreated(uint256 indexed id, address indexed beneficiary, uint256 requestedAmount, uint256 threshold);
    event Staked(address indexed user, uint256 indexed proposalId, uint256 amount);
    event Unstaked(address indexed user, uint256 indexed proposalId, uint256 amount);
    event ProposalExecuted(uint256 indexed id, address indexed beneficiary, uint256 amount);

    struct Proposal {
        address payable beneficiary;
        uint256 requestedAmount;
        uint256 convictionThreshold;
        uint256 totalStaked;
        uint256 lastUpdated;
        uint256 accumulatedConviction;
        bool executed;
    }

    address public immutable stakingToken;
    uint256 public nextProposalId = 1;

    mapping(uint256 => Proposal) public proposals;
    // proposalId => user => stakedAmount
    mapping(uint256 => mapping(address => uint256)) public userStake;

    constructor(address _stakingToken) {
        stakingToken = _stakingToken;
    }

    receive() external payable {}

    function createProposal(address payable beneficiary, uint256 requestedAmount, uint256 convictionThreshold)
        external
        returns (uint256 id)
    {
        id = nextProposalId++;
        proposals[id] = Proposal({
            beneficiary: beneficiary,
            requestedAmount: requestedAmount,
            convictionThreshold: convictionThreshold,
            totalStaked: 0,
            lastUpdated: block.timestamp,
            accumulatedConviction: 0,
            executed: false
        });

        emit ProposalCreated(id, beneficiary, requestedAmount, convictionThreshold);
    }

    /// @notice Updates and returns current accumulated conviction
    function getConviction(uint256 id) public view returns (uint256) {
        Proposal storage p = proposals[id];
        if (p.executed) return p.accumulatedConviction;

        uint256 elapsed = block.timestamp - p.lastUpdated;
        return p.accumulatedConviction + (p.totalStaked * elapsed);
    }

    function stake(uint256 id, uint256 amount) external {
        if (amount == 0) revert ZeroAmount();
        Proposal storage p = proposals[id];
        if (p.executed) revert ProposalAlreadyPassed();

        // Update accumulated conviction up to now
        p.accumulatedConviction = getConviction(id);
        p.lastUpdated = block.timestamp;

        p.totalStaked += amount;
        userStake[id][msg.sender] += amount;

        _safeTransferFrom(stakingToken, msg.sender, address(this), amount);
        emit Staked(msg.sender, id, amount);
    }

    function unstake(uint256 id, uint256 amount) external {
        if (amount == 0 || userStake[id][msg.sender] < amount) revert InsufficientStaked();
        Proposal storage p = proposals[id];

        p.accumulatedConviction = getConviction(id);
        p.lastUpdated = block.timestamp;

        p.totalStaked -= amount;
        userStake[id][msg.sender] -= amount;

        _safeTransfer(stakingToken, msg.sender, amount);
        emit Unstaked(msg.sender, id, amount);
    }

    function executeProposal(uint256 id) external {
        Proposal storage p = proposals[id];
        if (p.executed) revert ProposalAlreadyPassed();

        uint256 currentConviction = getConviction(id);
        if (currentConviction < p.convictionThreshold) revert ThresholdNotMet();

        p.executed = true;
        p.accumulatedConviction = currentConviction;

        (bool success,) = p.beneficiary.call{value: p.requestedAmount}("");
        require(success, "Payout failed");

        emit ProposalExecuted(id, p.beneficiary, p.requestedAmount);
    }

    function _safeTransfer(address token, address to, uint256 amount) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSignature("transfer(address,uint256)", to, amount));
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) revert TransferFailed();
    }

    function _safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, amount));
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) revert TransferFailed();
    }
}
