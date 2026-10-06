// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {OrderBookDEX} from "../src/02_DeFi/OrderBookDEX.sol";
import {ERC20Votes} from "../src/01_Tokens/ERC20Votes.sol";

contract OrderBookDEXTest is Test {
    OrderBookDEX public dex;
    ERC20Votes public weth;
    ERC20Votes public usdc;

    address public maker = address(0x11);
    address public taker = address(0x22);

    function setUp() public {
        weth = new ERC20Votes("Wrapped Ether", "WETH");
        usdc = new ERC20Votes("USD Coin", "USDC");

        dex = new OrderBookDEX(address(weth), address(usdc));

        weth.mint(maker, 10e18);
        usdc.mint(taker, 50_000e18);

        vm.prank(maker);
        weth.approve(address(dex), type(uint256).max);

        vm.prank(taker);
        usdc.approve(address(dex), type(uint256).max);
    }

    function test_PlaceAndFillSellOrder() public {
        // Maker places sell order: sell 2 WETH at price 3,000 USDC/WETH
        vm.prank(maker);
        uint256 orderId = dex.placeOrder(false, 3000e18, 2e18);

        // Taker fills 1 WETH (paying 3000 USDC)
        vm.prank(taker);
        dex.fillOrder(orderId, 1e18);

        assertEq(weth.balanceOf(taker), 1e18);
        assertEq(usdc.balanceOf(maker), 3000e18);

        // Taker fills remaining 1 WETH
        vm.prank(taker);
        dex.fillOrder(orderId, 1e18);

        assertEq(weth.balanceOf(taker), 2e18);
        assertEq(usdc.balanceOf(maker), 6000e18);
    }

    function test_CancelOrderRefundsMaker() public {
        vm.prank(maker);
        uint256 orderId = dex.placeOrder(false, 3000e18, 2e18);

        assertEq(weth.balanceOf(maker), 8e18);

        vm.prank(maker);
        dex.cancelOrder(orderId);

        assertEq(weth.balanceOf(maker), 10e18);
    }
}
