// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {VolatilityFeeHook} from "../src/02_DeFi/VolatilityFeeHook.sol";

contract VolatilityFeeHookTest is Test {
    VolatilityFeeHook public hook;

    function setUp() public {
        vm.warp(1000);
        hook = new VolatilityFeeHook();
    }

    function test_InitialStateAndBaselineFee() public {
        assertEq(hook.currentFeeBps(), 30);
    }

    function test_DynamicFeeIncreasesWithHighVolatility() public {
        // First observation
        hook.beforeSwap(1000e18);

        // Price jumps by 20% in the next block
        vm.warp(1012);
        uint24 newFee = hook.beforeSwap(1200e18);

        // Fee should have increased due to realized volatility
        assertGt(newFee, 30);
        assertLe(newFee, 200);
    }

    function test_OwnerCanSetStaticFee() public {
        hook.setStaticFee(75);
        assertEq(hook.currentFeeBps(), 75);

        // Unauthorized revert
        vm.prank(address(0xDEAD));
        vm.expectRevert(VolatilityFeeHook.Unauthorized.selector);
        hook.setStaticFee(50);
    }
}
