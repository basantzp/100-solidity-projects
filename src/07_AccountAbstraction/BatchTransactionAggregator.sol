// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title BatchTransactionAggregator
/// @notice Atomic multicall aggregator supporting optional failure tolerance and ETH value routing.
contract BatchTransactionAggregator {
    // --- Errors ---
    error CallFailed(uint256 index, bytes returnData);
    error InsufficientValue();
    error RefundFailed();

    // --- Structs ---
    struct Call {
        address target;
        uint256 value;
        bytes callData;
        bool allowFailure;
    }

    struct Result {
        bool success;
        bytes returnData;
    }

    /// @notice Execute multiple transactions atomically
    function aggregate(Call[] calldata calls) external payable returns (Result[] memory results) {
        uint256 totalValue = 0;
        for (uint256 i = 0; i < calls.length; i++) {
            totalValue += calls[i].value;
        }
        if (msg.value < totalValue) revert InsufficientValue();

        results = new Result[](calls.length);

        for (uint256 i = 0; i < calls.length; i++) {
            Call calldata c = calls[i];
            (bool success, bytes memory returnData) = c.target.call{value: c.value}(c.callData);

            if (!success && !c.allowFailure) {
                revert CallFailed(i, returnData);
            }

            results[i] = Result({success: success, returnData: returnData});
        }

        // Refund any leftover ETH
        uint256 leftover = address(this).balance;
        if (leftover > 0) {
            (bool refundSuccess,) = payable(msg.sender).call{value: leftover}("");
            if (!refundSuccess) revert RefundFailed();
        }
    }
}
