// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {GovernorBravo, IVotes} from "../src/03_Governance/GovernorBravo.sol";
import {ERC20Votes} from "../src/01_Tokens/ERC20Votes.sol";

contract TreasuryTarget {
    uint256 public treasuryValue;

    function setTreasuryValue(uint256 val) external {
        treasuryValue = val;
    }
}

contract GovernorBravoTest is Test {
    ERC20Votes public token;
    GovernorBravo public governor;
    TreasuryTarget public target;

    address public alice = address(0xA11CE);
    address public bob = address(0xB0B);

    function setUp() public {
        token = new ERC20Votes("DAO Token", "DAO");
        // votingDelay = 2 blocks, votingPeriod = 10 blocks, quorum = 4%
        governor = new GovernorBravo(IVotes(address(token)), 2, 10, 4);
        target = new TreasuryTarget();

        token.mint(alice, 100_000e18);
        token.mint(bob, 10_000e18);

        vm.prank(alice);
        token.delegate(alice);

        vm.prank(bob);
        token.delegate(bob);

        // Advance a block so delegation checkpoints are in place
        vm.roll(block.number + 1);
    }

    function test_ProposalLifecycleSuccessAndExecution() public {
        bytes memory callData = abi.encodeWithSelector(TreasuryTarget.setTreasuryValue.selector, 888);

        // Alice proposes
        vm.prank(alice);
        uint256 pid = governor.propose(address(target), callData);

        assertEq(uint256(governor.state(pid)), uint256(GovernorBravo.ProposalState.Pending));

        // Advance 2 blocks past voting delay
        vm.roll(block.number + 3);
        assertEq(uint256(governor.state(pid)), uint256(GovernorBravo.ProposalState.Active));

        // Alice votes FOR (support = 1)
        vm.prank(alice);
        governor.castVote(pid, 1);

        // Advance 10 blocks past voting period
        vm.roll(block.number + 11);
        assertEq(uint256(governor.state(pid)), uint256(GovernorBravo.ProposalState.Succeeded));

        // Execute proposal
        governor.execute(pid);
        assertEq(uint256(governor.state(pid)), uint256(GovernorBravo.ProposalState.Executed));
        assertEq(target.treasuryValue(), 888);
    }
}
