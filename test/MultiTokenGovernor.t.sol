// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {MultiTokenGovernor} from "../src/03_Governance/MultiTokenGovernor.sol";
import {ERC20Votes} from "../src/01_Tokens/ERC20Votes.sol";

contract MultiTokenGovernorTest is Test {
    MultiTokenGovernor public governor;
    ERC20Votes public capitalToken;
    ERC20Votes public communityToken;

    address public whale = address(0x1111);
    address public communityMember = address(0x2222);

    function setUp() public {
        vm.warp(10_000);
        capitalToken = new ERC20Votes("Capital Token", "CAP");
        communityToken = new ERC20Votes("Community Token", "COM");

        governor = new MultiTokenGovernor(address(capitalToken), address(communityToken));

        capitalToken.mint(whale, 150e18);
        communityToken.mint(communityMember, 20e18);
    }

    function test_ProposalPassesWithCapitalAndCommunitySupport() public {
        uint256 propId = governor.propose("Protocol Upgrade Proposal #1");

        vm.prank(whale);
        governor.voteWithCapital(propId, true);

        vm.prank(communityMember);
        governor.voteWithCommunity(propId, true);

        // Advance beyond 3 days
        vm.warp(10_000 + 3 days + 1);

        governor.execute(propId);
        (,,,,,, bool executed) = governor.proposals(propId);
        assertTrue(executed);
    }

    function test_CommunityVetoBlocksCapitalWhale() public {
        uint256 propId = governor.propose("Hostile Takeover Proposal");

        vm.prank(whale);
        governor.voteWithCapital(propId, true);

        // Community unites against the proposal
        vm.prank(communityMember);
        governor.voteWithCommunity(propId, false);

        vm.warp(10_000 + 3 days + 1);

        vm.expectRevert(MultiTokenGovernor.CommunityVetoTriggered.selector);
        governor.execute(propId);
    }
}
