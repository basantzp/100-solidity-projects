// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {TransientReentrancyGuard} from "../src/04_Security/TransientReentrancyGuard.sol";

contract VulnerableVault is TransientReentrancyGuard {
    mapping(address => uint256) public balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() external nonReentrant {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "Zero balance");

        // Vulnerable interaction before effects without guard
        (bool success,) = msg.sender.call{value: amount}("");
        if (!success) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        balances[msg.sender] = 0;
    }
}

contract ReentrancyAttacker {
    VulnerableVault public vault;

    constructor(VulnerableVault _vault) {
        vault = _vault;
    }

    function attack() external payable {
        vault.deposit{value: msg.value}();
        vault.withdraw();
    }

    receive() external payable {
        if (address(vault).balance >= 1 ether) {
            vault.withdraw();
        }
    }
}

contract TransientReentrancyGuardTest is Test {
    VulnerableVault vault;
    ReentrancyAttacker attacker;

    function setUp() public {
        vault = new VulnerableVault();
        attacker = new ReentrancyAttacker(vault);
        vm.deal(address(vault), 10 ether);
    }

    function test_ProtectsAgainstReentrancyAttack() public {
        vm.deal(address(attacker), 1 ether);

        // Attempt attack, should revert with ReentrantCall()
        vm.expectRevert(TransientReentrancyGuard.ReentrantCall.selector);
        attacker.attack{value: 1 ether}();
    }

    function test_NormalWithdrawSucceeds() public {
        address user = address(0x42);
        vm.deal(user, 5 ether);

        vm.prank(user);
        vault.deposit{value: 2 ether}();

        assertEq(vault.balances(user), 2 ether);

        vm.prank(user);
        vault.withdraw();

        assertEq(vault.balances(user), 0);
        assertEq(user.balance, 5 ether);
    }
}
