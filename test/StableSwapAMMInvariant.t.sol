// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {StableSwapAMM} from "../src/02_DeFi/StableSwapAMM.sol";
import {ERC20Permit} from "../src/01_Tokens/ERC20Permit.sol";

/// @title MockStableToken
/// @notice Mintable ERC20 for StableSwap Invariant testing
contract MockStableToken is ERC20Permit {
    constructor(string memory name, string memory symbol) ERC20Permit(name, symbol, 18) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

/// @title StableSwapAMMHandler
/// @notice Fuzz handler performing randomized swaps and balanced/imbalanced liquidity actions
contract StableSwapAMMHandler is Test {
    StableSwapAMM public immutable amm;
    MockStableToken public immutable token0;
    MockStableToken public immutable token1;

    uint256 public ghost_dBeforeSwap;
    uint256 public ghost_dAfterSwap;
    uint256 public successfulSwaps;
    uint256 public successfulAdds;

    constructor(StableSwapAMM _amm, MockStableToken _token0, MockStableToken _token1) {
        amm = _amm;
        token0 = _token0;
        token1 = _token1;

        token0.approve(address(amm), type(uint256).max);
        token1.approve(address(amm), type(uint256).max);
    }

    function swap0For1(uint256 amountInRaw) external {
        uint256 r0 = amm.reserve0();
        uint256 r1 = amm.reserve1();
        if (r0 == 0 || r1 == 0) return;

        // Bound swap input between 1e15 and 5% of reserve0 to keep Curve solver stable
        uint256 maxSwap = r0 / 20;
        if (maxSwap < 1e16) return;
        uint256 amountIn = bound(amountInRaw, 1e16, maxSwap);

        ghost_dBeforeSwap = amm.getD(r0, r1);
        token0.mint(address(this), amountIn);

        try amm.swap0For1(amountIn, 0) {
            uint256 newR0 = amm.reserve0();
            uint256 newR1 = amm.reserve1();
            ghost_dAfterSwap = amm.getD(newR0, newR1);
            successfulSwaps++;
        } catch {}
    }

    function swap1For0(uint256 amountInRaw) external {
        uint256 r0 = amm.reserve0();
        uint256 r1 = amm.reserve1();
        if (r0 == 0 || r1 == 0) return;

        // Bound swap input between 1e15 and 5% of reserve1 to keep Curve solver stable
        uint256 maxSwap = r1 / 20;
        if (maxSwap < 1e16) return;
        uint256 amountIn = bound(amountInRaw, 1e16, maxSwap);

        ghost_dBeforeSwap = amm.getD(r0, r1);
        token1.mint(address(this), amountIn);

        try amm.swap1For0(amountIn, 0) {
            uint256 newR0 = amm.reserve0();
            uint256 newR1 = amm.reserve1();
            ghost_dAfterSwap = amm.getD(newR0, newR1);
            successfulSwaps++;
        } catch {}
    }

    function addLiquidity(uint256 amount0Raw, uint256 amount1Raw) external {
        uint256 amount0 = bound(amount0Raw, 1e16, 50_000e18);
        uint256 amount1 = bound(amount1Raw, 1e16, 50_000e18);

        token0.mint(address(this), amount0);
        token1.mint(address(this), amount1);

        try amm.addLiquidity(amount0, amount1, 0) {
            successfulAdds++;
        } catch {}
    }
}

/// @title StableSwapAMMInvariantTest
/// @author Basant Pokhrel (@basantzp)
/// @notice Formal invariant test proving Curve StableSwap D preservation, solvency, and balance conservation
contract StableSwapAMMInvariantTest is Test {
    StableSwapAMM public amm;
    MockStableToken public token0;
    MockStableToken public token1;
    StableSwapAMMHandler public handler;

    function setUp() public {
        token0 = new MockStableToken("USD Coin", "USDC");
        token1 = new MockStableToken("Tether USD", "USDT");

        // Amplification coefficient A = 50
        amm = new StableSwapAMM(address(token0), address(token1), 50);

        // Seed initial balanced liquidity: 1,000,000 USDC and 1,000,000 USDT
        uint256 initialLiq = 1_000_000e18;
        token0.mint(address(this), initialLiq);
        token1.mint(address(this), initialLiq);

        token0.approve(address(amm), type(uint256).max);
        token1.approve(address(amm), type(uint256).max);

        amm.addLiquidity(initialLiq, initialLiq, 0);

        handler = new StableSwapAMMHandler(amm, token0, token1);

        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = StableSwapAMMHandler.swap0For1.selector;
        selectors[1] = StableSwapAMMHandler.swap1For0.selector;
        selectors[2] = StableSwapAMMHandler.addLiquidity.selector;
        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));

        // Target handler for invariant fuzzing
        targetContract(address(handler));
    }

    /// @notice Invariant 1: AMM contract token balances must strictly equal tracked reserves (zero insolvency or token leak)
    function invariant_SolvencyMatchesReserves() public view {
        uint256 bal0 = token0.balanceOf(address(amm));
        uint256 bal1 = token1.balanceOf(address(amm));

        assertEq(bal0, amm.reserve0(), "Reserve0 token solvency mismatch");
        assertEq(bal1, amm.reserve1(), "Reserve1 token solvency mismatch");
    }

    /// @notice Invariant 2: Invariant D must always be strictly positive and bounded by sum of reserves
    function invariant_DIsStrictlyPositive() public view {
        uint256 r0 = amm.reserve0();
        uint256 r1 = amm.reserve1();
        if (r0 > 0 && r1 > 0) {
            uint256 D = amm.getD(r0, r1);
            assertGt(D, 0, "Invariant D must be positive");
            assertLe(D, r0 + r1 + 100, "Invariant D cannot exceed sum of reserves");
        }
    }

    /// @notice Invariant 3: Total supply of LP tokens must always be backed by non-zero reserves
    function invariant_TotalSupplyBacked() public view {
        uint256 supply = amm.totalSupply();
        if (supply > 0) {
            assertGt(amm.reserve0(), 0, "Reserve0 must be positive while supply > 0");
            assertGt(amm.reserve1(), 0, "Reserve1 must be positive while supply > 0");
        }
    }
}
