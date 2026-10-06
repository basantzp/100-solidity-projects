// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {ConcentratedLiquidityPool} from "../src/02_DeFi/ConcentratedLiquidityPool.sol";
import {ERC20Votes} from "../src/01_Tokens/ERC20Votes.sol";

contract ConcentratedLiquidityPoolTest is Test {
    ConcentratedLiquidityPool public pool;
    ERC20Votes public token0;
    ERC20Votes public token1;

    address public alice = address(0xA11CE);
    address public bob = address(0xB0B);

    uint160 constant INITIAL_SQRT_PRICE = 79228162514264337593543950336; // 1:1 price (2^96)

    function setUp() public {
        token0 = new ERC20Votes("Token 0", "TK0");
        token1 = new ERC20Votes("Token 1", "TK1");

        pool = new ConcentratedLiquidityPool(address(token0), address(token1), INITIAL_SQRT_PRICE, 0);

        token0.mint(alice, 1000e18);
        token1.mint(alice, 1000e18);
        token0.mint(bob, 100e18);

        vm.startPrank(alice);
        token0.approve(address(pool), type(uint256).max);
        token1.approve(address(pool), type(uint256).max);
        vm.stopPrank();

        vm.prank(bob);
        token0.approve(address(pool), type(uint256).max);
    }

    function test_MintConcentratedLiquidity() public {
        vm.prank(alice);
        (uint256 a0, uint256 a1) = pool.mint(alice, -100, 100, 100e18);

        assertGt(a0, 0);
        assertGt(a1, 0);
        assertEq(pool.liquidity(), 100e18);
    }

    function test_SwapAcrossConcentratedRange() public {
        vm.prank(alice);
        pool.mint(alice, -100, 100, 1000e18);

        uint256 bobTk1Before = token1.balanceOf(bob);

        vm.prank(bob);
        uint256 amountOut = pool.swapExact0For1(10e18, bob);

        assertGt(amountOut, 0);
        assertEq(token1.balanceOf(bob) - bobTk1Before, amountOut);
    }
}
