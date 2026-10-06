// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {MEVBackrunShield} from "../src/08_Oracles/MEVBackrunShield.sol";
import {ERC20Votes} from "../src/01_Tokens/ERC20Votes.sol";

contract MEVBackrunShieldTest is Test {
    MEVBackrunShield public shield;
    ERC20Votes public token;

    address public owner = address(this);
    address public relayer = address(0x777);
    address public user = address(0xA11CE);
    address public searcher = address(0x5EA5);

    function setUp() public {
        shield = new MEVBackrunShield(relayer);
        token = new ERC20Votes("MEV Token", "MEV");

        token.mint(searcher, 1000e18);
        vm.prank(searcher);
        token.approve(address(shield), type(uint256).max);
    }

    function test_VerifySwapSucceedsWithinTolerance() public {
        vm.prank(relayer);
        // Expected 1,000, Actual 990 (1% slippage < 2% max allowed)
        shield.verifySwap(1000, 990, 200); // 200 bps = 2%
    }

    function test_VerifySwapRevertsOnExcessiveSlippage() public {
        vm.prank(relayer);
        // Expected 1,000, Actual 950 (5% slippage > 2% allowed)
        vm.expectRevert(MEVBackrunShield.ExcessiveSlippage.selector);
        shield.verifySwap(1000, 950, 200);
    }

    function test_DistributeBackrunArbitrageRebate() public {
        uint256 userBefore = token.balanceOf(user);
        uint256 ownerBefore = token.balanceOf(owner);

        // Searcher captures 100 tokens arbitrage and shares profit via shield
        // 80% to user (80 tokens), 20% to DAO owner (20 tokens)
        vm.prank(searcher);
        shield.distributeBackrunProfit(address(token), user, 100e18);

        assertEq(token.balanceOf(user) - userBefore, 80e18);
        assertEq(token.balanceOf(owner) - ownerBefore, 20e18);
    }
}
