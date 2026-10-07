// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {LiquidationEngine} from "../src/02_DeFi/LiquidationEngine.sol";
import {ERC20Votes} from "../src/01_Tokens/ERC20Votes.sol";

contract LiquidationEngineTest is Test {
    LiquidationEngine public engine;
    ERC20Votes public collateral;
    ERC20Votes public debt;

    address public borrower = address(0xB0B0);
    address public liquidator = address(0x1337);

    function setUp() public {
        vm.warp(10_000);
        engine = new LiquidationEngine();
        collateral = new ERC20Votes("Collateral", "COL");
        debt = new ERC20Votes("Debt Token", "DBT");

        collateral.mint(borrower, 100e18);
        debt.mint(liquidator, 1000e18);

        vm.prank(borrower);
        collateral.approve(address(engine), type(uint256).max);

        vm.prank(liquidator);
        debt.approve(address(engine), type(uint256).max);
    }

    function test_DutchAuctionPriceDecay() public {
        // Start auction: 10 COL collateral, 100 DBT debt, startPrice = 12 DBT/COL, floorPrice = 8 DBT/COL, duration = 1000s
        vm.prank(borrower);
        uint256 auctionId =
            engine.startAuction(borrower, address(collateral), address(debt), 100e18, 10e18, 12e18, 8e18, 1000);

        // Price at start
        assertEq(engine.getCurrentPrice(auctionId), 12e18);

        // Price after 500 seconds (halfway) -> 10 DBT/COL
        vm.warp(10_500);
        assertEq(engine.getCurrentPrice(auctionId), 10e18);

        // Price after expiry -> floor price 8 DBT/COL
        vm.warp(11_500);
        assertEq(engine.getCurrentPrice(auctionId), 8e18);
    }

    function test_LiquidatorPurchaseCollateral() public {
        vm.prank(borrower);
        uint256 auctionId =
            engine.startAuction(borrower, address(collateral), address(debt), 50e18, 10e18, 10e18, 5e18, 1000);

        // Warp to price = 5e18
        vm.warp(11_000);

        vm.prank(liquidator);
        uint256 purchased = engine.take(auctionId, 25e18);

        // At 5 DBT/COL, 25 DBT buys 5 COL
        assertEq(purchased, 5e18);
        assertEq(collateral.balanceOf(liquidator), 5e18);
    }
}
