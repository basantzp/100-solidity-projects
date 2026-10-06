// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {LiquidityBootstrappingPool} from "../src/02_DeFi/LiquidityBootstrappingPool.sol";
import {ERC20Votes} from "../src/01_Tokens/ERC20Votes.sol";

contract LiquidityBootstrappingPoolTest is Test {
    LiquidityBootstrappingPool public lbp;
    ERC20Votes public projectToken;
    ERC20Votes public usdc;

    address public buyer = address(0xBA);

    uint256 public startTime;
    uint256 public endTime;

    function setUp() public {
        projectToken = new ERC20Votes("Project Token", "PRJ");
        usdc = new ERC20Votes("USD Coin", "USDC");

        startTime = block.timestamp + 100;
        endTime = startTime + 1000;

        // Start weight: 90% PRJ / 10% USDC -> End weight: 50% PRJ / 50% USDC
        // Initial pool: 1,000,000 PRJ and 50,000 USDC
        lbp = new LiquidityBootstrappingPool(
            address(projectToken), address(usdc), startTime, endTime, 90, 50, 1_000_000e18, 50_000e18
        );

        projectToken.mint(address(lbp), 1_000_000e18);
        usdc.mint(address(lbp), 50_000e18);

        usdc.mint(buyer, 10_000e18);
        vm.prank(buyer);
        usdc.approve(address(lbp), type(uint256).max);
    }

    function test_DynamicWeightDecayOverTime() public {
        (uint256 w0, uint256 c0) = lbp.getWeights();
        assertEq(w0, 90);
        assertEq(c0, 10);

        // Advance to 50% through auction (elapsed = 500)
        vm.warp(startTime + 500);
        (uint256 wMid, uint256 cMid) = lbp.getWeights();
        assertEq(wMid, 70); // halfway between 90 and 50
        assertEq(cMid, 30);

        // Advance to end
        vm.warp(endTime);
        (uint256 wEnd, uint256 cEnd) = lbp.getWeights();
        assertEq(wEnd, 50);
        assertEq(cEnd, 50);
    }

    function test_SwapDuringSale() public {
        vm.warp(startTime + 100);

        uint256 buyerPrjBefore = projectToken.balanceOf(buyer);

        vm.prank(buyer);
        uint256 prjOut = lbp.swapCollateralForProject(1_000e18, 0);

        assertGt(prjOut, 0);
        assertEq(projectToken.balanceOf(buyer) - buyerPrjBefore, prjOut);
    }
}
