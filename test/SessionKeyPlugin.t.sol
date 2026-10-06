// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {SessionKeyPlugin} from "../src/07_AccountAbstraction/SessionKeyPlugin.sol";

contract GameTarget {
    uint256 public score;
    address public lastPlayer;

    function playMove(uint256 points) external payable {
        score += points;
        lastPlayer = msg.sender;
    }

    function transferAdmin(address) external pure {
        // High privileged function
    }
}

contract SessionKeyPluginTest is Test {
    SessionKeyPlugin public account;
    GameTarget public game;

    address public owner = address(this);
    address public sessionKey = address(0x5E55);

    function setUp() public {
        account = new SessionKeyPlugin();
        game = new GameTarget();
    }

    function test_SessionKeyExecutionWithinScope() public {
        // Allow sessionKey to call game.playMove for next 1 hour with max 1 ETH spend
        uint256 expiry = block.timestamp + 1 hours;
        account.addSessionKey(sessionKey, address(game), GameTarget.playMove.selector, 1 ether, expiry);

        bytes memory moveData = abi.encodeWithSelector(GameTarget.playMove.selector, 50);

        // Session key executes game move
        vm.prank(sessionKey);
        account.executeWithSessionKey(address(game), 0, moveData);

        assertEq(game.score(), 50);
    }

    function test_UnauthorizedTargetOrSelectorReverts() public {
        uint256 expiry = block.timestamp + 1 hours;
        account.addSessionKey(sessionKey, address(game), GameTarget.playMove.selector, 0, expiry);

        // Session key tries to call transferAdmin (unauthorized selector)
        bytes memory badCall = abi.encodeWithSelector(GameTarget.transferAdmin.selector, address(0xBAD));

        vm.prank(sessionKey);
        vm.expectRevert(SessionKeyPlugin.SelectorNotAllowed.selector);
        account.executeWithSessionKey(address(game), 0, badCall);
    }

    function test_ExpiredSessionKeyReverts() public {
        uint256 expiry = block.timestamp + 100;
        account.addSessionKey(sessionKey, address(game), GameTarget.playMove.selector, 0, expiry);

        // Advance 101 seconds
        vm.warp(expiry + 1);

        bytes memory moveData = abi.encodeWithSelector(GameTarget.playMove.selector, 10);

        vm.prank(sessionKey);
        vm.expectRevert(SessionKeyPlugin.SessionExpired.selector);
        account.executeWithSessionKey(address(game), 0, moveData);
    }
}
