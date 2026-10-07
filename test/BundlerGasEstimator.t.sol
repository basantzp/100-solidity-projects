// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {BundlerGasEstimator} from "../src/07_AccountAbstraction/BundlerGasEstimator.sol";

contract DummyReceiver {
    uint256 public counter;

    function ping() external {
        counter += 1;
    }
}

contract BundlerGasEstimatorTest is Test {
    BundlerGasEstimator public estimator;
    DummyReceiver public receiver;

    function setUp() public {
        estimator = new BundlerGasEstimator();
        receiver = new DummyReceiver();
    }

    function test_EstimateGas() public {
        bytes memory data = abi.encodeWithSignature("ping()");
        BundlerGasEstimator.UserOpSimulation memory sim = estimator.estimateUserOpGas(address(receiver), 0, data);

        assertTrue(sim.executionSuccess);
        assertGt(sim.executionGas, 0);
        assertGt(sim.preVerificationGas, 0);
        assertEq(receiver.counter(), 1);
    }
}
