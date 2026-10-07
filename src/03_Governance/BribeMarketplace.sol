// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title BribeMarketplace
/// @notice Votium / Curve-style gauge vote incentive distributor allowing sponsors to bribe voters for protocol gauges.
contract BribeMarketplace {
    // --- Errors ---
    error ZeroAmount();
    error AlreadyClaimed();
    error VotingStillActive();
    error NoVotesRecorded();
    error TransferFailed();

    // --- Events ---
    event BribeDeposited(
        uint256 indexed proposalId, address indexed sponsor, address indexed rewardToken, uint256 amount
    );
    event BribeClaimed(
        uint256 indexed proposalId, address indexed voter, address indexed rewardToken, uint256 rewardAmount
    );

    struct BribePool {
        address rewardToken;
        uint256 totalReward;
        uint256 totalVotes;
        uint256 votingDeadline;
    }

    uint256 public nextPoolId = 1;
    mapping(uint256 => BribePool) public pools;
    mapping(uint256 => mapping(address => uint256)) public voterWeight;
    mapping(uint256 => mapping(address => bool)) public hasClaimed;

    function createBribePool(address rewardToken, uint256 rewardAmount, uint256 votingDeadline)
        external
        returns (uint256 poolId)
    {
        if (rewardAmount == 0) revert ZeroAmount();

        poolId = nextPoolId++;
        pools[poolId] = BribePool({
            rewardToken: rewardToken, totalReward: rewardAmount, totalVotes: 0, votingDeadline: votingDeadline
        });

        _safeTransferFrom(rewardToken, msg.sender, address(this), rewardAmount);
        emit BribeDeposited(poolId, msg.sender, rewardToken, rewardAmount);
    }

    function recordVote(uint256 poolId, address voter, uint256 weight) external {
        BribePool storage p = pools[poolId];
        require(block.timestamp <= p.votingDeadline, "Voting deadline passed");
        if (weight == 0) revert ZeroAmount();

        voterWeight[poolId][voter] += weight;
        p.totalVotes += weight;
    }

    function claimBribe(uint256 poolId) external returns (uint256 reward) {
        BribePool storage p = pools[poolId];
        if (block.timestamp <= p.votingDeadline) revert VotingStillActive();
        if (hasClaimed[poolId][msg.sender]) revert AlreadyClaimed();

        uint256 weight = voterWeight[poolId][msg.sender];
        if (weight == 0 || p.totalVotes == 0) revert NoVotesRecorded();

        hasClaimed[poolId][msg.sender] = true;
        reward = (p.totalReward * weight) / p.totalVotes;

        _safeTransfer(p.rewardToken, msg.sender, reward);
        emit BribeClaimed(poolId, msg.sender, p.rewardToken, reward);
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
