// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {LeveragedYieldFarm} from "../src/02_DeFi/LeveragedYieldFarm.sol";
import {ERC20Votes} from "../src/01_Tokens/ERC20Votes.sol";

contract LeveragedYieldFarmTest is Test {
    LeveragedYieldFarm public farm;
    ERC20Votes public asset;

    address public user = address(0xCAFE);

    function setUp() public {
        vm.warp(10_000);
        asset = new ERC20Votes("USDC Stable", "USDC");
        farm = new LeveragedYieldFarm(address(asset));

        asset.mint(user, 10_000e18);
        asset.mint(address(farm), 50_000e18); // Reserve liquidity for farm leverage

        vm.prank(user);
        asset.approve(address(farm), type(uint256).max);
    }

    function test_OpenAndClosePositionWithYield() public {
        vm.prank(user);
        farm.openPosition(100e18, 3); // 3x leverage -> 100 collateral + 200 borrowed = 300 farmed

        (uint256 col, uint256 borrowed, uint256 shares,) = farm.positions(user);
        assertEq(col, 100e18);
        assertEq(borrowed, 200e18);
        assertEq(shares, 300e18);

        // Warp 1 year (365 days)
        vm.warp(10_000 + 365 days);

        // Pending yield should be ~12% on 300 = 36
        uint256 accruedYield = farm.getPendingYield(user);
        assertEq(accruedYield, 36e18);

        // Close position
        uint256 initialBal = asset.balanceOf(user);
        vm.prank(user);
        uint256 payout = farm.closePosition();

        assertEq(payout, 136e18); // 100 principal + 36 yield
        assertEq(asset.balanceOf(user), initialBal + 136e18);
    }
}
