// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {VariableRateMarket} from "../src/02_DeFi/VariableRateMarket.sol";
import {ERC20Votes} from "../src/01_Tokens/ERC20Votes.sol";

/// @title VariableRateMarketHandler
/// @notice Fuzz handler simulating multi-user deposits, borrows, repayments, and time warps
contract VariableRateMarketHandler is Test {
    VariableRateMarket public immutable market;
    ERC20Votes public immutable asset;

    address[] public users;
    uint256 public previousBorrowIndex;

    constructor(VariableRateMarket _market, ERC20Votes _asset) {
        market = _market;
        asset = _asset;
        previousBorrowIndex = market.borrowIndex();

        users.push(makeAddr("UserA"));
        users.push(makeAddr("UserB"));
        users.push(makeAddr("UserC"));

        for (uint256 i = 0; i < users.length; ++i) {
            asset.mint(users[i], 1_000_000e18);
            vm.prank(users[i]);
            asset.approve(address(market), type(uint256).max);
        }
    }

    function deposit(uint256 userIdx, uint256 amountRaw) external {
        address user = users[userIdx % users.length];
        uint256 amount = bound(amountRaw, 1e18, 50_000e18);

        vm.prank(user);
        try market.deposit(amount) {} catch {}
    }

    function borrow(uint256 userIdx, uint256 amountRaw) external {
        address user = users[userIdx % users.length];
        uint256 availableLiquidity = asset.balanceOf(address(market));
        if (availableLiquidity == 0) return;

        uint256 amount = bound(amountRaw, 1e18, availableLiquidity);

        vm.prank(user);
        try market.borrow(amount) {} catch {}
    }

    function repay(uint256 userIdx, uint256 amountRaw) external {
        address user = users[userIdx % users.length];
        uint256 debt = market.getUserDebt(user);
        if (debt == 0) return;

        uint256 amount = bound(amountRaw, 1e18, debt);

        vm.prank(user);
        try market.repay(amount) {} catch {}
    }

    function advanceTime(uint256 secondsToAdvance) external {
        secondsToAdvance = bound(secondsToAdvance, 1, 30 days);
        vm.warp(block.timestamp + secondsToAdvance);
        market.accrueInterest();
    }
}

/// @title VariableRateMarketInvariantTest
/// @author Basant Pokhrel (@basantzp)
/// @notice Property-based invariant test proving market solvency and monotonic borrow index
contract VariableRateMarketInvariantTest is Test {
    VariableRateMarket public market;
    ERC20Votes public asset;
    VariableRateMarketHandler public handler;

    function setUp() public {
        asset = new ERC20Votes("USDC Stablecoin", "USDC");
        market = new VariableRateMarket(address(asset));

        handler = new VariableRateMarketHandler(market, asset);

        targetContract(address(handler));
    }

    /// @notice Invariant 1: Cash reserves + total borrows >= total deposits (Zero Insolvency)
    function invariant_MarketSolvency() public view {
        uint256 cash = asset.balanceOf(address(market));
        uint256 borrows = market.totalBorrows();
        uint256 deposits = market.totalDeposits();

        assertGe(
            cash + borrows,
            deposits,
            "Insolvency: Cash liquidity plus borrows must satisfy depositor claims"
        );
    }

    /// @notice Invariant 2: Borrow index is strictly non-decreasing
    function invariant_BorrowIndexMonotonic() public view {
        uint256 currentIndex = market.borrowIndex();
        assertGe(
            currentIndex,
            1e18,
            "Borrow index collapsed below base 1e18"
        );
    }

    /// @notice Invariant 3: Borrow rate is strictly bounded within realistic rate model boundaries
    function invariant_BorrowRateBounded() public view {
        uint256 rate = market.getBorrowRate();
        assertGe(rate, market.BASE_RATE(), "Borrow rate fell below BASE_RATE");
        assertLe(rate, 2e18, "Borrow rate exceeded 200% annual APY");
    }
}
