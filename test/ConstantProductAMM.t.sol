// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {ConstantProductAMM} from "../src/02_DeFi/ConstantProductAMM.sol";
import {ERC20Permit} from "../src/01_Tokens/ERC20Permit.sol";

contract MockToken is ERC20Permit {
    constructor(string memory name, string memory symbol) ERC20Permit(name, symbol, 18) {
        _mint(msg.sender, 1_000_000e18);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract ConstantProductAMMTest is Test {
    MockToken token0;
    MockToken token1;
    ConstantProductAMM amm;

    address alice = address(0x1);
    address bob = address(0x2);

    function setUp() public {
        MockToken rawA = new MockToken("Token A", "TKA");
        MockToken rawB = new MockToken("Token B", "TKB");

        // Sort addresses
        if (address(rawA) < address(rawB)) {
            token0 = rawA;
            token1 = rawB;
        } else {
            token0 = rawB;
            token1 = rawA;
        }

        amm = new ConstantProductAMM(address(token0), address(token1));

        token0.mint(alice, 100_000e18);
        token1.mint(alice, 100_000e18);
        token0.mint(bob, 10_000e18);
        token1.mint(bob, 10_000e18);
    }

    function test_AddInitialLiquidity() public {
        vm.startPrank(alice);
        token0.approve(address(amm), 10_000e18);
        token1.approve(address(amm), 10_000e18);

        uint256 shares = amm.addLiquidity(10_000e18, 10_000e18, alice);
        vm.stopPrank();

        assertEq(shares, 10_000e18);
        (uint112 r0, uint112 r1,) = amm.getReserves();
        assertEq(r0, 10_000e18);
        assertEq(r1, 10_000e18);
    }

    function test_SwapToken0ForToken1() public {
        // Alice adds initial liquidity: 10,000 TKA and 10,000 TKB
        vm.startPrank(alice);
        token0.approve(address(amm), 10_000e18);
        token1.approve(address(amm), 10_000e18);
        amm.addLiquidity(10_000e18, 10_000e18, alice);
        vm.stopPrank();

        // Bob swaps 1,000 TKA for TKB
        // dy = (y * 997 * dx) / (x * 1000 + 997 * dx)
        // dy = (10000 * 997 * 1000) / (10000 * 1000 + 997 * 1000) = 9970000 / 10997 ≈ 906.5e18
        vm.startPrank(bob);
        token0.transfer(address(amm), 1000e18);
        uint256 amount1Out = 906e18;
        amm.swap(0, amount1Out, bob);
        vm.stopPrank();

        assertEq(token1.balanceOf(bob), 10_000e18 + amount1Out);
    }

    function test_RemoveLiquidity() public {
        vm.startPrank(alice);
        token0.approve(address(amm), 10_000e18);
        token1.approve(address(amm), 10_000e18);
        uint256 shares = amm.addLiquidity(10_000e18, 10_000e18, alice);

        amm.removeLiquidity(shares, alice);
        vm.stopPrank();

        (uint112 r0, uint112 r1,) = amm.getReserves();
        assertEq(r0, 0);
        assertEq(r1, 0);
    }
}
