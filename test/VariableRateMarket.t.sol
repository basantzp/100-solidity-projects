// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {VariableRateMarket} from "../src/02_DeFi/VariableRateMarket.sol";
import {ERC20Votes} from "../src/01_Tokens/ERC20Votes.sol";

contract VariableRateMarketTest is Test {
    VariableRateMarket public market;
    ERC20Votes public usdc;

    address public lender = address(0x11);
    address public borrower = address(0x22);

    function setUp() public {
        usdc = new ERC20Votes("USD Coin", "USDC");
        market = new VariableRateMarket(address(usdc));

        usdc.mint(lender, 100_000e18);
        usdc.mint(borrower, 10_000e18);

        vm.prank(lender);
        usdc.approve(address(market), type(uint256).max);

        vm.prank(borrower);
        usdc.approve(address(market), type(uint256).max);
    }

    function test_DepositBorrowAndInterestAccrual() public {
        // Lender deposits 100,000 USDC
        vm.prank(lender);
        market.deposit(100_000e18);

        // Utilization is initially 0%, rate = 2%
        assertEq(market.getBorrowRate(), 0.02e18);

        // Borrower borrows 50,000 USDC (50% utilization < 80% kink)
        vm.prank(borrower);
        market.borrow(50_000e18);

        // 50% utilization rate: 2% + (0.50 / 0.80) * 4% = 2% + 2.5% = 4.5%
        assertEq(market.getBorrowRate(), 0.045e18);

        // Advance 1 year (31,536,000 seconds)
        vm.warp(block.timestamp + 31536000);
        market.accrueInterest();

        // Debt should increase by ~4.5% (approx 52,250 USDC)
        uint256 debt = market.getUserDebt(borrower);
        assertGt(debt, 50_000e18);
        assertApproxEqRel(debt, 52_250e18, 0.01e18);
    }

    function test_KinkSurgeAboveOptimalUtilization() public {
        vm.prank(lender);
        market.deposit(100_000e18);

        // Borrow 90,000 USDC (90% utilization > 80% optimal)
        vm.prank(borrower);
        market.borrow(90_000e18);

        // Steep penalty rate applies:
        // Base(2%) + Slope1(4%) + ((90-80)/(100-80)) * Slope2(75%) = 6% + 0.5 * 75% = 43.5%
        uint256 rate = market.getBorrowRate();
        assertEq(rate, 0.435e18);
    }
}
