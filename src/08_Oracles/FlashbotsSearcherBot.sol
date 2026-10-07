// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title FlashbotsSearcherBot
/// @notice On-chain atomic triangular arbitrage executor with miner/builder bribe payment.
contract FlashbotsSearcherBot {
    // --- Errors ---
    error InsufficientArbitrageProfit();
    error ExecutionFailed();
    error Unauthorized();

    // --- Events ---
    event ArbitrageExecuted(uint256 startAmount, uint256 finalAmount, uint256 builderBribe);

    address public immutable owner;

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {}

    /// @notice Executes atomic triangular trade across 3 pools and verifies positive net yield
    function executeTriangularArbitrage(
        address[] calldata pools,
        bytes[] calldata swapData,
        uint256 startAmount,
        uint256 minProfit,
        uint256 builderBribe
    ) external payable onlyOwner returns (uint256 netProfit) {
        require(pools.length == 3 && swapData.length == 3, "Invalid swap route");

        uint256 initialBalance = address(this).balance;

        // Execute step 1, 2, and 3
        for (uint256 i = 0; i < 3; i++) {
            (bool success,) = pools[i].call(swapData[i]);
            if (!success) revert ExecutionFailed();
        }

        uint256 postBalance = address(this).balance;
        if (postBalance < initialBalance + minProfit + builderBribe) {
            revert InsufficientArbitrageProfit();
        }

        // Pay builder/searcher bribe via coinbase transfer
        if (builderBribe > 0) {
            (bool bribeSuccess,) = block.coinbase.call{value: builderBribe}("");
            require(bribeSuccess, "Bribe failed");
        }

        netProfit = address(this).balance - initialBalance;
        emit ArbitrageExecuted(startAmount, postBalance, builderBribe);
    }
}
