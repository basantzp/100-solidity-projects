// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {AutoCompoundingVault} from "../src/02_DeFi/AutoCompoundingVault.sol";
import {ERC20Votes} from "../src/01_Tokens/ERC20Votes.sol";

contract AutoCompoundingVaultTest is Test {
    AutoCompoundingVault public vault;
    ERC20Votes public underlying;

    address public alice = address(0xA11CE);
    address public keeper = address(0xB0B);

    function setUp() public {
        underlying = new ERC20Votes("Staked Asset", "sAST");
        vault = new AutoCompoundingVault(address(underlying));

        underlying.mint(alice, 1000e18);
        underlying.mint(keeper, 1000e18);

        vm.prank(alice);
        underlying.approve(address(vault), type(uint256).max);

        vm.prank(keeper);
        underlying.approve(address(vault), type(uint256).max);
    }

    function test_DepositHarvestAndShareAppreciation() public {
        vm.prank(alice);
        uint256 shares = vault.deposit(100e18);

        assertEq(shares, 100e18);
        assertEq(vault.getPricePerShare(), 1e18);

        // Keeper injects 20 e18 harvested yield into the vault
        vm.prank(keeper);
        vault.harvestSimulatedYield(20e18);

        // Vault total assets is now 120 e18 for 100 shares -> 1 share = 1.2 underlying
        assertEq(vault.totalAssets(), 120e18);
        assertEq(vault.getPricePerShare(), 1.2e18);

        // Alice withdraws all shares and receives 120 e18
        vm.prank(alice);
        uint256 assetsReceived = vault.withdraw(shares);

        assertEq(assetsReceived, 120e18);
    }
}
