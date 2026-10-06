// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {TWAMM} from "../src/02_DeFi/TWAMM.sol";
import {ERC20Votes} from "../src/01_Tokens/ERC20Votes.sol";

contract TWAMMTest is Test {
    TWAMM public twamm;
    ERC20Votes public token0;
    ERC20Votes public token1;

    address public alice = address(0xA11CE);

    function setUp() public {
        token0 = new ERC20Votes("Token 0", "TK0");
        token1 = new ERC20Votes("Token 1", "TK1");

        // Initial pool: 1,000,000 TK0 and 1,000,000 TK1
        twamm = new TWAMM(address(token0), address(token1), 1_000_000e18, 1_000_000e18);

        // Fund TWAMM with reserves
        token0.mint(address(twamm), 1_000_000e18);
        token1.mint(address(twamm), 1_000_000e18);

        // Alice wants to sell 10,000 TK0 over 100 blocks
        token0.mint(alice, 10_000e18);
        vm.prank(alice);
        token0.approve(address(twamm), type(uint256).max);
    }

    function test_LongTermOrderLinearExecution() public {
        vm.prank(alice);
        uint256 orderId = twamm.submitLongTermOrder(true, 10_000e18, 100);

        // Advance 50 blocks (halfway)
        vm.roll(block.number + 50);

        uint256 aliceTk1Before = token1.balanceOf(alice);
        vm.prank(alice);
        uint256 proceeds = twamm.claimProceeds(orderId);

        assertGt(proceeds, 0);
        assertEq(token1.balanceOf(alice) - aliceTk1Before, proceeds);

        // Advance past end (100 blocks total)
        vm.roll(block.number + 60);

        vm.prank(alice);
        uint256 finalProceeds = twamm.claimProceeds(orderId);
        assertGt(finalProceeds, 0);
    }

    function test_CancelOrderRefundsUnexecutedSlices() public {
        vm.prank(alice);
        uint256 orderId = twamm.submitLongTermOrder(true, 10_000e18, 100);

        // Advance 20 blocks
        vm.roll(block.number + 20);

        uint256 aliceTk0Before = token0.balanceOf(alice);

        // Cancel order: 80% should be refunded
        vm.prank(alice);
        twamm.cancelOrder(orderId);

        uint256 refunded = token0.balanceOf(alice) - aliceTk0Before;
        assertEq(refunded, 8_000e18);
    }
}
