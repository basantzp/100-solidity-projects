// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {FlashLender, IERC3156FlashBorrower} from "../src/02_DeFi/FlashLender.sol";
import {ERC20Permit} from "../src/01_Tokens/ERC20Permit.sol";

contract MockFlashToken is ERC20Permit {
    constructor() ERC20Permit("Flash", "FLS", 18) {
        _mint(msg.sender, 1_000_000e18);
    }
}

contract MockBorrower is IERC3156FlashBorrower {
    FlashLender lender;

    constructor(FlashLender _lender) {
        lender = _lender;
    }

    function onFlashLoan(address, address token, uint256 amount, uint256 fee, bytes calldata)
        external
        override
        returns (bytes32)
    {
        // Approve lender to pull loan + fee
        ERC20Permit(token).approve(address(lender), amount + fee);
        return lender.CALLBACK_SUCCESS();
    }
}

contract FlashLenderTest is Test {
    MockFlashToken token;
    FlashLender lender;
    MockBorrower borrower;

    function setUp() public {
        token = new MockFlashToken();

        address[] memory tokens = new address[](1);
        tokens[0] = address(token);

        lender = new FlashLender(tokens);
        borrower = new MockBorrower(lender);

        // Fund lender with 100,000 tokens
        token.transfer(address(lender), 100_000e18);

        // Fund borrower with enough to cover 0.09% fee
        token.transfer(address(borrower), 100e18);
    }

    function test_FlashLoanExecution() public {
        uint256 loanAmount = 10_000e18;
        uint256 fee = lender.flashFee(address(token), loanAmount);
        assertEq(fee, 9e18); // 9 bips of 10,000 = 9

        uint256 lenderBalanceBefore = token.balanceOf(address(lender));

        lender.flashLoan(borrower, address(token), loanAmount, "");

        assertEq(token.balanceOf(address(lender)), lenderBalanceBefore + fee);
    }
}
