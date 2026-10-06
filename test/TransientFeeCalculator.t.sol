// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {TransientFeeCalculator} from "../src/06_CancunEVM/TransientFeeCalculator.sol";
import {ERC20Votes} from "../src/01_Tokens/ERC20Votes.sol";

contract BatchFeeRouter {
    TransientFeeCalculator public immutable calc;

    constructor(TransientFeeCalculator _calc) {
        calc = _calc;
    }

    function executeBatchRoute(address token, address beneficiary) external returns (uint256 totalSettled) {
        calc.recordFee(token, 10e18);
        require(calc.getTransientFee(token) == 10e18, "Step 1 failed");

        calc.recordFee(token, 15e18);
        require(calc.getTransientFee(token) == 25e18, "Step 2 failed");

        totalSettled = calc.settleFee(token, beneficiary);
        require(calc.getTransientFee(token) == 0, "Reset failed");
    }
}

contract TransientFeeCalculatorTest is Test {
    TransientFeeCalculator public calc;
    BatchFeeRouter public router;
    ERC20Votes public token;

    address public beneficiary = address(0xBEEF);

    function setUp() public {
        calc = new TransientFeeCalculator();
        router = new BatchFeeRouter(calc);
        token = new ERC20Votes("Fee Token", "FEE");
        token.mint(address(calc), 1000e18);
    }

    function test_RecordAndSettleTransientFeeInSingleTx() public {
        uint256 beneficiaryBefore = token.balanceOf(beneficiary);

        // Within one atomic multi-step transaction, transient storage accumulates
        uint256 settled = router.executeBatchRoute(address(token), beneficiary);

        assertEq(settled, 25e18);
        assertEq(token.balanceOf(beneficiary) - beneficiaryBefore, 25e18);

        // After transaction ends, transient storage is guaranteed 0
        assertEq(calc.getTransientFee(address(token)), 0);
    }
}
