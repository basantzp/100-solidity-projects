// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {TWAPOracle} from "../src/08_Oracles/TWAPOracle.sol";

contract TWAPOracleTest is Test {
    TWAPOracle public oracle;

    function setUp() public {
        // 30 minute window
        oracle = new TWAPOracle(1800, 2000e8);
    }

    function test_ConsultTWAPOverTime() public {
        // Price stays at $2,000 for 10 minutes (600s)
        vm.warp(block.timestamp + 600);
        oracle.update(2000e8);

        // Price rises to $2,200 for next 10 minutes (600s)
        vm.warp(block.timestamp + 600);
        oracle.update(2200e8);

        // Price rises to $2,400 for next 10 minutes (600s)
        vm.warp(block.timestamp + 600);
        oracle.update(2400e8);

        // Across the 30-minute window (1800s):
        // (2000*600 + 2200*600 + 2400*600) / 1800 = 6600 / 3 = 2200
        uint224 twap = oracle.consult();
        assertEq(twap, 2200e8);
    }

    function test_SingleBlockFlashLoanManipulationFails() public {
        vm.warp(block.timestamp + 1800);
        oracle.update(2000e8);

        // Attacker attempts to update price in the very same block
        vm.expectRevert(TWAPOracle.PeriodNotElapsed.selector);
        oracle.update(100_000e8);
    }
}
