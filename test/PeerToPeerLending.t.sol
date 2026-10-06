// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {PeerToPeerLending} from "../src/02_DeFi/PeerToPeerLending.sol";
import {ERC20Votes} from "../src/01_Tokens/ERC20Votes.sol";

contract PeerToPeerLendingTest is Test {
    PeerToPeerLending public lending;
    ERC20Votes public usdc;
    ERC20Votes public weth;

    address public borrower = address(0xAA);
    address public lender = address(0xBB);

    function setUp() public {
        usdc = new ERC20Votes("USD Coin", "USDC");
        weth = new ERC20Votes("Wrapped Ether", "WETH");
        lending = new PeerToPeerLending();

        weth.mint(borrower, 5e18); // Borrower has 5 WETH collateral
        usdc.mint(lender, 10_000e18); // Lender has 10,000 USDC principal

        vm.prank(borrower);
        weth.approve(address(lending), type(uint256).max);

        vm.prank(lender);
        usdc.approve(address(lending), type(uint256).max);
    }

    function test_LoanLifecycle_RequestFundRepay() public {
        // Borrower requests 3,000 USDC with 100 USDC interest, 30 days duration, posting 2 WETH collateral
        vm.prank(borrower);
        uint256 loanId = lending.requestLoan(address(usdc), 3000e18, 100e18, address(weth), 2e18, 30 days);

        assertEq(weth.balanceOf(address(lending)), 2e18);

        // Lender funds loan
        vm.prank(lender);
        lending.fundLoan(loanId);

        assertEq(usdc.balanceOf(borrower), 3000e18);

        // Borrower repays 3,100 USDC
        usdc.mint(borrower, 100e18); // Mint interest for borrower
        vm.prank(borrower);
        usdc.approve(address(lending), type(uint256).max);

        vm.prank(borrower);
        lending.repayLoan(loanId);

        // Borrower got collateral back
        assertEq(weth.balanceOf(borrower), 5e18);
        // Lender received principal + interest
        assertEq(usdc.balanceOf(lender), 10_100e18);
    }

    function test_DefaultSeizesCollateral() public {
        vm.prank(borrower);
        uint256 loanId = lending.requestLoan(address(usdc), 3000e18, 100e18, address(weth), 2e18, 30 days);

        vm.prank(lender);
        lending.fundLoan(loanId);

        // Advance 31 days past due date
        vm.warp(block.timestamp + 31 days);

        // Lender seizes collateral
        vm.prank(lender);
        lending.claimDefaultedCollateral(loanId);

        assertEq(weth.balanceOf(lender), 2e18);
    }
}
