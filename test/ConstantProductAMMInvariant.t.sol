// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {ConstantProductAMM} from "../src/02_DeFi/ConstantProductAMM.sol";
import {ERC20Permit} from "../src/01_Tokens/ERC20Permit.sol";

/// @title MockAMMToken
/// @notice Mintable ERC20 for AMM Invariant testing
contract MockAMMToken is ERC20Permit {
    constructor(string memory name, string memory symbol) ERC20Permit(name, symbol, 18) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

/// @title ConstantProductAMMHandler
/// @notice Fuzz handler performing randomized swaps and liquidity actions
contract ConstantProductAMMHandler is Test {
    ConstantProductAMM public immutable amm;
    MockAMMToken public immutable token0;
    MockAMMToken public immutable token1;

    uint256 public ghost_kBeforeSwap;
    uint256 public ghost_kAfterSwap;
    uint256 public successfulSwaps;

    constructor(ConstantProductAMM _amm, MockAMMToken _token0, MockAMMToken _token1) {
        amm = _amm;
        token0 = _token0;
        token1 = _token1;
    }

    function swapToken0ForToken1(uint256 amountInRaw) external {
        uint256 amountIn = bound(amountInRaw, 1e12, 1000e18);

        (uint112 r0, uint112 r1,) = amm.getReserves();
        if (r0 == 0 || r1 == 0) return;

        uint256 amountInWithFee = amountIn * 997;
        uint256 amountOut = (amountInWithFee * uint256(r1)) / ((uint256(r0) * 1000) + amountInWithFee);

        if (amountOut == 0 || amountOut >= uint256(r1)) return;

        ghost_kBeforeSwap = uint256(r0) * uint256(r1);

        token0.mint(address(amm), amountIn);
        try amm.swap(0, amountOut, address(this)) {
            (uint112 newR0, uint112 newR1,) = amm.getReserves();
            ghost_kAfterSwap = uint256(newR0) * uint256(newR1);
            successfulSwaps++;
        } catch {}
    }

    function swapToken1ForToken0(uint256 amountInRaw) external {
        uint256 amountIn = bound(amountInRaw, 1e12, 1000e18);

        (uint112 r0, uint112 r1,) = amm.getReserves();
        if (r0 == 0 || r1 == 0) return;

        uint256 amountInWithFee = amountIn * 997;
        uint256 amountOut = (amountInWithFee * uint256(r0)) / ((uint256(r1) * 1000) + amountInWithFee);

        if (amountOut == 0 || amountOut >= uint256(r0)) return;

        ghost_kBeforeSwap = uint256(r0) * uint256(r1);

        token1.mint(address(amm), amountIn);
        try amm.swap(amountOut, 0, address(this)) {
            (uint112 newR0, uint112 newR1,) = amm.getReserves();
            ghost_kAfterSwap = uint256(newR0) * uint256(newR1);
            successfulSwaps++;
        } catch {}
    }
}

/// @title ConstantProductAMMInvariantTest
/// @author Basant Pokhrel (@basantzp)
/// @notice Formal invariant test proving k non-decreasing growth and pool reserve solvency
contract ConstantProductAMMInvariantTest is Test {
    ConstantProductAMM public amm;
    MockAMMToken public token0;
    MockAMMToken public token1;
    ConstantProductAMMHandler public handler;

    function setUp() public {
        token0 = new MockAMMToken("Token 0", "TK0");
        token1 = new MockAMMToken("Token 1", "TK1");

        // Ensure token ordering
        if (address(token0) > address(token1)) {
            (token0, token1) = (token1, token0);
        }

        amm = new ConstantProductAMM(address(token0), address(token1));

        // Seed initial liquidity: 1,000,000 of both tokens
        uint256 initialLiq = 1_000_000e18;
        token0.mint(address(this), initialLiq);
        token1.mint(address(this), initialLiq);
        token0.approve(address(amm), type(uint256).max);
        token1.approve(address(amm), type(uint256).max);
        amm.addLiquidity(initialLiq, initialLiq, address(this));

        handler = new ConstantProductAMMHandler(amm, token0, token1);

        targetContract(address(handler));
    }

    /// @notice Invariant 1: AMM constant product invariant k strictly never decreases across swaps
    function invariant_KNeverDecreases() public view {
        if (handler.successfulSwaps() > 0) {
            assertGe(
                handler.ghost_kAfterSwap(),
                handler.ghost_kBeforeSwap(),
                "Invariant Violation: Constant product k decreased after swap"
            );
        }
    }

    /// @notice Invariant 2: Physical contract token balances strictly cover stored reserves
    function invariant_SolvencyMatchesReserves() public view {
        (uint112 r0, uint112 r1,) = amm.getReserves();
        assertGe(
            token0.balanceOf(address(amm)),
            uint256(r0),
            "Insolvency: token0 balance less than reserve0"
        );
        assertGe(
            token1.balanceOf(address(amm)),
            uint256(r1),
            "Insolvency: token1 balance less than reserve1"
        );
    }

    /// @notice Invariant 3: LP total supply respects minimum locked liquidity floor
    function invariant_MinimumLiquidityLocked() public view {
        assertGe(
            amm.totalSupply(),
            1000,
            "LP total supply below minimum locked liquidity"
        );
    }
}
