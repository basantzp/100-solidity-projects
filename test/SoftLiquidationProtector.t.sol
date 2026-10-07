// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {SoftLiquidationProtector} from "../src/08_Oracles/SoftLiquidationProtector.sol";

contract SoftLiquidationProtectorTest is Test {
    SoftLiquidationProtector public protector;

    address public user = address(0x4444);
    address public collateral = address(0xC);
    address public debt = address(0xD);

    function setUp() public {
        protector = new SoftLiquidationProtector(collateral, debt);

        // Position: 10 ETH collateral, 20,000 USD debt
        protector.setPosition(user, 10e18, 20_000e18);
    }

    function test_SoftLiquidationRebalancing() public {
        // ETH at $2500 -> 10 * 2500 = $25,000 / $20,000 = 1.25x (12500 bps) -> healthy
        assertEq(protector.getHealthFactor(user, 2500e18), 12500);

        // ETH drops to $2100 -> 10 * 2100 = $21,000 / $20,000 = 1.05x (10500 bps) -> soft liquidation triggered!
        assertEq(protector.getHealthFactor(user, 2100e18), 10500);

        // Keeper executes soft liquidation
        (uint256 colSold, uint256 debtRepaid) = protector.rebalance(user, 2100e18);
        assertEq(colSold, 2e18); // 20% of 10 ETH = 2 ETH sold
        assertEq(debtRepaid, 4200e18); // 2 * 2100 = 4200 debt repaid

        // Remaining: 8 ETH collateral, 15,800 debt
        // Health factor improves: (8 * 2100) / 15,800 = 16,800 / 15,800 = 1.063x
        assertGt(protector.getHealthFactor(user, 2100e18), 10500);
    }
}
