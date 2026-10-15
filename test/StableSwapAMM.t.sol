// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {StableSwapAMM} from "../src/02_DeFi/StableSwapAMM.sol";
import {ERC20Votes} from "../src/01_Tokens/ERC20Votes.sol";

contract StableSwapAMMTest is Test {
    StableSwapAMM public amm;
    ERC20Votes public usdc;
    ERC20Votes public usdt;

    address public lp = address(0x11);
    address public trader = address(0x22);

    function setUp() public {
        usdc = new ERC20Votes("USD Coin", "USDC");
        usdt = new ERC20Votes("Tether USD", "USDT");

        // A = 100 amplification
        amm = new StableSwapAMM(address(usdc), address(usdt), 100);

        usdc.mint(lp, 1_000_000e18);
        usdt.mint(lp, 1_000_000e18);
        usdc.mint(trader, 10_000e18);

        vm.startPrank(lp);
        usdc.approve(address(amm), type(uint256).max);
        usdt.approve(address(amm), type(uint256).max);
        amm.addLiquidity(500_000e18, 500_000e18, 0);
        vm.stopPrank();

        vm.prank(trader);
        usdc.approve(address(amm), type(uint256).max);
    }

    function test_InitialLiquidityInvariant() public {
        uint256 D = amm.getD(500_000e18, 500_000e18);
        // For equal reserves, D equals sum of reserves
        assertApproxEqAbs(D, 1_000_000e18, 100);
    }

    function test_NearZeroSlippageSwap() public {
        uint256 amountIn = 1_000e18; // 1,000 USDC swap
        uint256 usdtBefore = usdt.balanceOf(trader);

        vm.prank(trader);
        uint256 amountOut = amm.swap0For1(amountIn, 999e18);

        // Due to A = 100, 1000 USDC yields nearly 1000 USDT (slippage < 0.01%)
        assertGt(amountOut, 999e18);
        assertLe(amountOut, amountIn);
        assertEq(usdt.balanceOf(trader) - usdtBefore, amountOut);
    }

    function test_Swap1For0_NearZeroSlippage() public {
        usdt.mint(trader, 5_000e18);
        vm.prank(trader);
        usdt.approve(address(amm), type(uint256).max);

        uint256 amountIn = 2_000e18;
        uint256 usdcBefore = usdc.balanceOf(trader);

        vm.prank(trader);
        uint256 amountOut = amm.swap1For0(amountIn, 1998e18);

        assertGt(amountOut, 1998e18);
        assertLe(amountOut, amountIn);
        assertEq(usdc.balanceOf(trader) - usdcBefore, amountOut);
    }

    function test_RemoveLiquidity_Proportional() public {
        uint256 lpShares = amm.balanceOf(lp);
        uint256 burnShares = lpShares / 2; // burn 50% of LP shares

        uint256 usdcBefore = usdc.balanceOf(lp);
        uint256 usdtBefore = usdt.balanceOf(lp);

        vm.prank(lp);
        (uint256 amount0, uint256 amount1) = amm.removeLiquidity(burnShares, 240_000e18, 240_000e18);

        assertEq(amount0, 250_000e18);
        assertEq(amount1, 250_000e18);
        assertEq(usdc.balanceOf(lp) - usdcBefore, 250_000e18);
        assertEq(usdt.balanceOf(lp) - usdtBefore, 250_000e18);
        assertEq(amm.balanceOf(lp), lpShares - burnShares);
    }
}
