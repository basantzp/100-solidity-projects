// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {FixedTermBond} from "../src/02_DeFi/FixedTermBond.sol";
import {ERC20Votes} from "../src/01_Tokens/ERC20Votes.sol";

contract FixedTermBondTest is Test {
    FixedTermBond public bondMarket;
    ERC20Votes public usdc;

    address public issuer = address(0x11);
    address public investor = address(0x22);

    function setUp() public {
        usdc = new ERC20Votes("USD Coin", "USDC");
        bondMarket = new FixedTermBond();

        // Issuer has 10,000 USDC to reserve for 100 bonds of par $100
        usdc.mint(issuer, 10_000e18);
        usdc.mint(investor, 10_000e18);

        vm.prank(issuer);
        usdc.approve(address(bondMarket), type(uint256).max);

        vm.prank(investor);
        usdc.approve(address(bondMarket), type(uint256).max);
    }

    function test_IssueBuyAndRedeemBondFlow() public {
        uint256 maturity = block.timestamp + 90 days;

        // Issuer issues 100 bonds: $100 face value, sold at $95 discount (5.26% yield)
        vm.prank(issuer);
        uint256 bondId = bondMarket.issueBond(address(usdc), 100, 100e18, 95e18, maturity);

        // Investor buys 10 bonds for 950 USDC
        uint256 issuerBefore = usdc.balanceOf(issuer);
        vm.prank(investor);
        bondMarket.buyBonds(bondId, 10);

        assertEq(usdc.balanceOf(issuer) - issuerBefore, 950e18);
        assertEq(bondMarket.bondBalances(bondId, investor), 10);

        // Before maturity, redemption fails
        vm.prank(investor);
        vm.expectRevert(FixedTermBond.BondNotMatured.selector);
        bondMarket.redeemBonds(bondId, 10);

        // Warp past maturity (90 days)
        vm.warp(maturity + 1);

        uint256 investorBefore = usdc.balanceOf(investor);
        vm.prank(investor);
        bondMarket.redeemBonds(bondId, 10);

        // Investor receives 10 * 100 = 1,000 USDC (earned 50 USDC profit)
        assertEq(usdc.balanceOf(investor) - investorBefore, 1000e18);
        assertEq(bondMarket.bondBalances(bondId, investor), 0);
    }
}
