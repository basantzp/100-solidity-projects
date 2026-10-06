// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {VestingWallet} from "../src/01_Tokens/VestingWallet.sol";
import {ERC20Permit} from "../src/01_Tokens/ERC20Permit.sol";

contract MockVestingToken is ERC20Permit {
    constructor() ERC20Permit("Vesting", "VST", 18) {
        _mint(msg.sender, 1_000_000e18);
    }
}

contract VestingWalletTest is Test {
    MockVestingToken token;
    VestingWallet wallet;
    address beneficiary = address(0x42);

    uint64 start;
    uint64 duration = 100 days;
    uint64 cliff = 20 days;

    function setUp() public {
        token = new MockVestingToken();
        start = uint64(block.timestamp);

        wallet = new VestingWallet(beneficiary, start, duration, cliff);
        token.transfer(address(wallet), 1000e18);
    }

    function test_BeforeCliff_ZeroReleasable() public {
        vm.warp(start + 10 days);
        assertEq(wallet.vestedAmount(address(token), uint64(block.timestamp)), 0);
    }

    function test_AfterCliff_LinearVesting() public {
        // Warp to 50 days (50% of duration)
        vm.warp(start + 50 days);

        uint256 vested = wallet.vestedAmount(address(token), uint64(block.timestamp));
        assertEq(vested, 500e18); // 50% of 1000

        wallet.release(address(token));
        assertEq(token.balanceOf(beneficiary), 500e18);
    }

    function test_AfterDuration_FullRelease() public {
        vm.warp(start + 120 days);

        uint256 vested = wallet.vestedAmount(address(token), uint64(block.timestamp));
        assertEq(vested, 1000e18);

        wallet.release(address(token));
        assertEq(token.balanceOf(beneficiary), 1000e18);
    }
}
