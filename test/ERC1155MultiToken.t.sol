// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {ERC1155MultiToken} from "../src/01_Tokens/ERC1155MultiToken.sol";

contract Mock1155 is ERC1155MultiToken {
    constructor() ERC1155MultiToken("https://token.io/api/{id}.json") {}

    function mint(address to, uint256 id, uint256 amount) external {
        _mint(to, id, amount, "");
    }
}

contract ERC1155MultiTokenTest is Test {
    Mock1155 token;
    address alice = address(0x1);
    address bob = address(0x2);

    function setUp() public {
        token = new Mock1155();
        token.mint(alice, 1, 100);
        token.mint(alice, 2, 50);
    }

    function test_Balances() public view {
        assertEq(token.balanceOf(1, alice), 100);
        assertEq(token.balanceOf(2, alice), 50);
    }

    function test_SafeTransferFrom() public {
        vm.prank(alice);
        token.safeTransferFrom(alice, bob, 1, 30, "");

        assertEq(token.balanceOf(1, alice), 70);
        assertEq(token.balanceOf(1, bob), 30);
    }

    function test_SafeBatchTransferFrom() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 20;
        amounts[1] = 10;

        vm.prank(alice);
        token.safeBatchTransferFrom(alice, bob, ids, amounts, "");

        assertEq(token.balanceOf(1, bob), 20);
        assertEq(token.balanceOf(2, bob), 10);
    }
}
