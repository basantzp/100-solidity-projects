// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {ERC4626YieldVault} from "../src/01_Tokens/ERC4626YieldVault.sol";
import {ERC20Permit} from "../src/01_Tokens/ERC20Permit.sol";

contract MockUnderlyingToken is ERC20Permit {
    constructor() ERC20Permit("Underlying", "UND", 18) {
        _mint(msg.sender, 1_000_000e18);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract ERC4626YieldVaultTest is Test {
    MockUnderlyingToken asset;
    ERC4626YieldVault vault;

    address alice = address(0x1);
    address bob = address(0x2);

    function setUp() public {
        asset = new MockUnderlyingToken();
        vault = new ERC4626YieldVault(asset, "Vault Shares", "vUND");

        asset.mint(alice, 10_000e18);
        asset.mint(bob, 10_000e18);
    }

    function test_DepositAndWithdraw() public {
        vm.startPrank(alice);
        asset.approve(address(vault), 1000e18);
        uint256 shares = vault.deposit(1000e18, alice);
        vm.stopPrank();

        assertGt(shares, 0);
        assertEq(vault.totalAssets(), 1000e18);

        vm.startPrank(alice);
        uint256 assetsReceived = vault.redeem(shares, alice, alice);
        vm.stopPrank();

        assertApproxEqAbs(assetsReceived, 1000e18, 1e15); // near 1000e18 due to virtual shares offset
    }

    function test_InflationAttackMitigation() public {
        // Attacker (alice) deposits minimal amount (1 wei)
        vm.startPrank(alice);
        asset.approve(address(vault), 1);
        vault.deposit(1, alice);

        // Attacker attempts donation attack: directly transfers 1000e18 to vault
        asset.transfer(address(vault), 1000e18);
        vm.stopPrank();

        // Victim (bob) deposits 1000e18
        vm.startPrank(bob);
        asset.approve(address(vault), 1000e18);
        uint256 bobShares = vault.deposit(1000e18, bob);
        vm.stopPrank();

        // Due to virtual shares offset, bob receives non-zero shares and does NOT lose funds!
        assertGt(bobShares, 0);
    }
}
