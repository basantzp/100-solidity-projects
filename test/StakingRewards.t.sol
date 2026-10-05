// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {StakingRewards} from "../src/02_DeFi/StakingRewards.sol";
import {ERC20Permit} from "../src/01_Tokens/ERC20Permit.sol";

contract MockStakingToken is ERC20Permit {
    constructor() ERC20Permit("Staking", "STK", 18) {
        _mint(msg.sender, 1_000_000e18);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract StakingRewardsTest is Test {
    MockStakingToken stakingToken;
    MockStakingToken rewardsToken;
    StakingRewards staking;

    address alice = address(0x1);
    address bob = address(0x2);

    function setUp() public {
        stakingToken = new MockStakingToken();
        rewardsToken = new MockStakingToken();

        staking = new StakingRewards(address(stakingToken), address(rewardsToken));

        stakingToken.mint(alice, 1000e18);
        stakingToken.mint(bob, 1000e18);

        // Fund staking contract with rewards and notify
        rewardsToken.mint(address(this), 70_000e18);
        rewardsToken.transfer(address(staking), 70_000e18);
        staking.notifyRewardAmount(70_000e18); // 10,000 per day over 7 days
    }

    function test_StakeAndEarnRewards() public {
        vm.startPrank(alice);
        stakingToken.approve(address(staking), 100e18);
        staking.stake(100e18);
        vm.stopPrank();

        assertEq(staking.balanceOf(alice), 100e18);
        assertEq(staking.totalSupply(), 100e18);

        // Advance time by 1 day (86400 seconds)
        vm.warp(block.timestamp + 1 days);

        // Alice earned ~10,000 reward tokens
        uint256 earnedAlice = staking.earned(alice);
        assertApproxEqAbs(earnedAlice, 10_000e18, 1e18);

        // Alice claims rewards
        vm.prank(alice);
        staking.getReward();

        assertApproxEqAbs(rewardsToken.balanceOf(alice), 10_000e18, 1e18);
    }

    function test_WithdrawStakedTokens() public {
        vm.startPrank(alice);
        stakingToken.approve(address(staking), 100e18);
        staking.stake(100e18);

        staking.withdraw(50e18);
        vm.stopPrank();

        assertEq(staking.balanceOf(alice), 50e18);
        assertEq(stakingToken.balanceOf(alice), 950e18);
    }
}
