// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {ERC20Votes} from "../src/01_Tokens/ERC20Votes.sol";

contract ERC20VotesTest is Test {
    ERC20Votes public token;
    address public alice = address(0xA11CE);
    address public bob = address(0xB0B);

    function setUp() public {
        token = new ERC20Votes("Governance Token", "GOV");
    }

    function test_DelegationAndVotingPower() public {
        token.mint(alice, 1000e18);
        assertEq(token.getVotes(alice), 0);

        // Alice delegates to herself
        vm.prank(alice);
        token.delegate(alice);
        assertEq(token.getVotes(alice), 1000e18);

        // Alice delegates to Bob
        vm.prank(alice);
        token.delegate(bob);
        assertEq(token.getVotes(alice), 0);
        assertEq(token.getVotes(bob), 1000e18);
    }

    function test_HistoricalVotesQuery() public {
        token.mint(alice, 500e18);

        vm.prank(alice);
        token.delegate(alice);

        uint256 block1 = block.number;
        vm.roll(block1 + 1);

        token.mint(alice, 300e18);

        uint256 block2 = block.number;
        vm.roll(block2 + 1);

        assertEq(token.getPastVotes(alice, block1), 500e18);
        assertEq(token.getPastVotes(alice, block2), 800e18);
        assertEq(token.getVotes(alice), 800e18);
    }

    function test_PastVotesRevertsOnCurrentOrFutureBlock() public {
        vm.expectRevert(ERC20Votes.BlockNotYetMined.selector);
        token.getPastVotes(alice, block.number);
    }
}
