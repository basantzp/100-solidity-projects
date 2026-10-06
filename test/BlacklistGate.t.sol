// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {BlacklistGate} from "../src/04_Security/BlacklistGate.sol";

contract GatedTokenTransfer is BlacklistGate {
    mapping(address => uint256) public balances;

    function mint(address to, uint256 amount) external notBlacklisted(to) {
        balances[to] += amount;
    }

    function transfer(address to, uint256 amount) external notBlacklisted(msg.sender) notBlacklisted(to) {
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
}

contract BlacklistGateTest is Test {
    GatedTokenTransfer public token;
    address public alice = address(0xA11CE);
    address public bob = address(0xB0B);

    function setUp() public {
        token = new GatedTokenTransfer();
        token.mint(alice, 1000);
    }

    function test_NormalTransferAllowed() public {
        vm.prank(alice);
        token.transfer(bob, 200);

        assertEq(token.balances(bob), 200);
    }

    function test_SenderBlacklistedReverts() public {
        token.setBlacklisted(alice, true);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(BlacklistGate.AccountBlacklisted.selector, alice));
        token.transfer(bob, 100);
    }

    function test_RecipientBlacklistedReverts() public {
        token.setBlacklisted(bob, true);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(BlacklistGate.AccountBlacklisted.selector, bob));
        token.transfer(bob, 100);
    }
}
