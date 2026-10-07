// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {MultiAssetPool} from "../src/02_DeFi/MultiAssetPool.sol";
import {ERC20Votes} from "../src/01_Tokens/ERC20Votes.sol";

contract MultiAssetPoolTest is Test {
    MultiAssetPool public pool;
    ERC20Votes public tokenA;
    ERC20Votes public tokenB;
    ERC20Votes public tokenC;

    address public alice = address(0xA11CE);
    address public bob = address(0xB0B);

    function setUp() public {
        tokenA = new ERC20Votes("Token A", "TKA");
        tokenB = new ERC20Votes("Token B", "TKB");
        tokenC = new ERC20Votes("Token C", "TKC");

        address[] memory tokens = new address[](3);
        tokens[0] = address(tokenA);
        tokens[1] = address(tokenB);
        tokens[2] = address(tokenC);

        uint256[] memory weights = new uint256[](3);
        weights[0] = 5000; // 50%
        weights[1] = 2500; // 25%
        weights[2] = 2500; // 25%

        pool = new MultiAssetPool(tokens, weights);

        tokenA.mint(alice, 1000e18);
        tokenB.mint(alice, 1000e18);
        tokenC.mint(alice, 1000e18);

        tokenA.mint(bob, 1000e18);

        vm.startPrank(alice);
        tokenA.approve(address(pool), type(uint256).max);
        tokenB.approve(address(pool), type(uint256).max);
        tokenC.approve(address(pool), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(bob);
        tokenA.approve(address(pool), type(uint256).max);
        vm.stopPrank();
    }

    function test_AddAndRemoveLiquidity() public {
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 100e18;
        amounts[1] = 50e18;
        amounts[2] = 50e18;

        vm.prank(alice);
        uint256 shares = pool.addLiquidity(amounts, 1e18);
        assertGt(shares, 0);
        assertEq(pool.sharesOf(alice), shares);

        // Remove half liquidity
        uint256[] memory minOut = new uint256[](3);
        vm.prank(alice);
        uint256[] memory out = pool.removeLiquidity(shares / 2, minOut);
        assertEq(out[0], 50e18);
        assertEq(out[1], 25e18);
        assertEq(out[2], 25e18);
    }

    function test_SwapAssets() public {
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 100e18;
        amounts[1] = 100e18;
        amounts[2] = 100e18;

        vm.prank(alice);
        pool.addLiquidity(amounts, 1e18);

        // Bob swaps tokenA for tokenB
        vm.prank(bob);
        uint256 out = pool.swap(address(tokenA), address(tokenB), 10e18, 1);
        assertGt(out, 0);
        assertEq(tokenB.balanceOf(bob), out);
    }
}
