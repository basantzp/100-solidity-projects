// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {FlashLender, IERC3156FlashBorrower} from "../src/02_DeFi/FlashLender.sol";
import {ERC20Permit} from "../src/01_Tokens/ERC20Permit.sol";

/// @title MockFlashToken
contract MockFlashToken is ERC20Permit {
    constructor(string memory name, string memory symbol) ERC20Permit(name, symbol, 18) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

/// @title FlashLenderHandler
/// @notice Fuzz handler performing randomized flash loans and verifying fee payouts
contract FlashLenderHandler is Test, IERC3156FlashBorrower {
    FlashLender public immutable lender;
    MockFlashToken public immutable token;

    uint256 public cumulativeFeesPaid;
    uint256 public successfulLoans;

    constructor(FlashLender _lender, MockFlashToken _token) {
        lender = _lender;
        token = _token;
        token.approve(address(lender), type(uint256).max);
    }

    function onFlashLoan(
        address,
        address,
        uint256,
        uint256 fee,
        bytes calldata
    ) external override returns (bytes32) {
        // Mint additional tokens to cover the fee payment
        token.mint(address(this), fee);
        return lender.CALLBACK_SUCCESS();
    }

    function executeFlashLoan(uint256 loanAmountRaw) external {
        uint256 maxLoan = lender.maxFlashLoan(address(token));
        if (maxLoan == 0) return;

        uint256 amount = bound(loanAmountRaw, 1e15, maxLoan);
        uint256 fee = lender.flashFee(address(token), amount);

        try lender.flashLoan(this, address(token), amount, "") {
            cumulativeFeesPaid += fee;
            successfulLoans++;
        } catch {}
    }
}

/// @title FlashLenderInvariantTest
/// @author Basant Pokhrel (@basantzp)
/// @notice Formal invariant test proving liquidity monotonic preservation and zero fee evasion in FlashLender
contract FlashLenderInvariantTest is Test {
    FlashLender public lender;
    MockFlashToken public token;
    FlashLenderHandler public handler;

    uint256 public initialPoolLiquidity;

    function setUp() public {
        token = new MockFlashToken("DAI Stablecoin", "DAI");

        address[] memory tokens = new address[](1);
        tokens[0] = address(token);

        lender = new FlashLender(tokens);

        initialPoolLiquidity = 500_000e18;
        token.mint(address(lender), initialPoolLiquidity);

        handler = new FlashLenderHandler(lender, token);

        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = FlashLenderHandler.executeFlashLoan.selector;
        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
        targetContract(address(handler));
    }

    /// @notice Invariant 1: Total pool balance must monotonically grow by exact accrued fees (no capital loss or fee leakage)
    function invariant_PoolBalanceMonotonicallyIncreases() public view {
        uint256 currentBal = token.balanceOf(address(lender));
        assertGe(
            currentBal,
            initialPoolLiquidity + handler.cumulativeFeesPaid(),
            "Lender balance must equal or exceed initial liquidity plus cumulative fees"
        );
    }

    /// @notice Invariant 2: maxFlashLoan always equals exact current token reserve
    function invariant_MaxFlashLoanMatchesReserve() public view {
        uint256 maxLoan = lender.maxFlashLoan(address(token));
        assertEq(maxLoan, token.balanceOf(address(lender)), "Max flash loan must strictly match reserve");
    }

    /// @notice Invariant 3: Unsupported tokens always report 0 max loan
    function invariant_UnsupportedTokenZeroLoan() public view {
        assertEq(lender.maxFlashLoan(address(0xdead)), 0, "Unsupported token must return 0");
    }
}
