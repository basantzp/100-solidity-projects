// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {WETH9} from "../src/01_Tokens/WETH9.sol";

contract WETH9Test is Test {
    WETH9 weth;
    address alice = address(0x1);

    function setUp() public {
        weth = new WETH9();
        vm.deal(alice, 10 ether);
    }

    function test_DepositAndWithdraw() public {
        vm.prank(alice);
        weth.deposit{value: 5 ether}();

        assertEq(weth.balanceOf(alice), 5 ether);
        assertEq(weth.totalSupply(), 5 ether);
        assertEq(address(weth).balance, 5 ether);

        vm.prank(alice);
        weth.withdraw(3 ether);

        assertEq(weth.balanceOf(alice), 2 ether);
        assertEq(alice.balance, 8 ether);
    }

    function test_FallbackDeposit() public {
        vm.prank(alice);
        (bool success,) = address(weth).call{value: 2 ether}("");
        assertTrue(success);
        assertEq(weth.balanceOf(alice), 2 ether);
    }
}
