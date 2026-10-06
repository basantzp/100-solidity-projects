// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {BatchTransactionAggregator} from "../src/07_AccountAbstraction/BatchTransactionAggregator.sol";

contract CounterTarget {
    uint256 public count;

    function increment() external {
        count += 1;
    }

    function failingCall() external pure {
        revert("Intentional failure");
    }
}

contract BatchTransactionAggregatorTest is Test {
    BatchTransactionAggregator public aggregator;
    CounterTarget public c1;
    CounterTarget public c2;

    function setUp() public {
        aggregator = new BatchTransactionAggregator();
        c1 = new CounterTarget();
        c2 = new CounterTarget();
    }

    function test_AtomicBatchExecution() public {
        BatchTransactionAggregator.Call[] memory calls = new BatchTransactionAggregator.Call[](2);

        calls[0] = BatchTransactionAggregator.Call({
            target: address(c1),
            value: 0,
            callData: abi.encodeWithSelector(CounterTarget.increment.selector),
            allowFailure: false
        });

        calls[1] = BatchTransactionAggregator.Call({
            target: address(c2),
            value: 0,
            callData: abi.encodeWithSelector(CounterTarget.increment.selector),
            allowFailure: false
        });

        aggregator.aggregate(calls);

        assertEq(c1.count(), 1);
        assertEq(c2.count(), 1);
    }

    function test_AllowFailureTolerance() public {
        BatchTransactionAggregator.Call[] memory calls = new BatchTransactionAggregator.Call[](2);

        // Call 0 succeeds
        calls[0] = BatchTransactionAggregator.Call({
            target: address(c1),
            value: 0,
            callData: abi.encodeWithSelector(CounterTarget.increment.selector),
            allowFailure: false
        });

        // Call 1 fails but has allowFailure = true
        calls[1] = BatchTransactionAggregator.Call({
            target: address(c2),
            value: 0,
            callData: abi.encodeWithSelector(CounterTarget.failingCall.selector),
            allowFailure: true
        });

        BatchTransactionAggregator.Result[] memory results = aggregator.aggregate(calls);

        assertTrue(results[0].success);
        assertFalse(results[1].success);
        assertEq(c1.count(), 1);
    }
}
