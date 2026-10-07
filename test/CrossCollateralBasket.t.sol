// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {CrossCollateralBasket} from "../src/02_DeFi/CrossCollateralBasket.sol";
import {ERC20Votes} from "../src/01_Tokens/ERC20Votes.sol";

contract CrossCollateralBasketTest is Test {
    CrossCollateralBasket public basket;
    ERC20Votes public debtToken;
    ERC20Votes public weth;
    ERC20Votes public wbtc;

    address public user = address(0xAA11);

    function setUp() public {
        debtToken = new ERC20Votes("USDC Debt", "USDC");
        weth = new ERC20Votes("Wrapped ETH", "WETH");
        wbtc = new ERC20Votes("Wrapped BTC", "WBTC");

        basket = new CrossCollateralBasket(address(debtToken));

        // Setup collateral configs:
        // WETH: price $2000 (2000e18), LTV 80% (8000 bps)
        basket.addSupportedToken(address(weth), 8000, 2000e18);
        // WBTC: price $60,000 (60000e18), LTV 75% (7500 bps)
        basket.addSupportedToken(address(wbtc), 7500, 60000e18);

        // Mint liquidity
        debtToken.mint(address(basket), 1_000_000e18);
        weth.mint(user, 10e18);
        wbtc.mint(user, 1e18);

        vm.startPrank(user);
        weth.approve(address(basket), type(uint256).max);
        wbtc.approve(address(basket), type(uint256).max);
        debtToken.approve(address(basket), type(uint256).max);
        vm.stopPrank();
    }

    function test_DepositAndBorrowAgainstMultiCollateral() public {
        // User deposits 1 WETH ($2000 * 80% = $1600 borrowing power)
        vm.prank(user);
        basket.depositCollateral(address(weth), 1e18);

        assertEq(basket.calculateBorrowingPower(user), 1600e18);

        // User also deposits 0.1 WBTC ($6000 * 75% = $4500 borrowing power)
        vm.prank(user);
        basket.depositCollateral(address(wbtc), 0.1e18);

        // Total power = 1600 + 4500 = 6100 USD
        assertEq(basket.calculateBorrowingPower(user), 6100e18);

        // User borrows 5000 USDC
        vm.prank(user);
        basket.borrow(5000e18);

        assertEq(debtToken.balanceOf(user), 5000e18);
        assertEq(basket.userDebt(user), 5000e18);

        // Borrowing more than 6100 fails
        vm.prank(user);
        vm.expectRevert(CrossCollateralBasket.ExceedsBorrowingPower.selector);
        basket.borrow(1500e18);

        // Repaying debt
        vm.prank(user);
        basket.repay(2000e18);
        assertEq(basket.userDebt(user), 3000e18);
    }
}
