// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {CrossChainTokenBridge} from "../src/09_CrossChain/CrossChainTokenBridge.sol";
import {ERC20Votes} from "../src/01_Tokens/ERC20Votes.sol";

contract CrossChainTokenBridgeTest is Test {
    CrossChainTokenBridge public bridgeSource;
    CrossChainTokenBridge public bridgeDest;

    ERC20Votes public tokenSource;
    ERC20Votes public tokenDest;

    address public validator = address(0xBA1);
    address public alice = address(0xA11CE);
    address public bob = address(0xB0B);

    function setUp() public {
        tokenSource = new ERC20Votes("Native Token", "NAT");
        tokenDest = new ERC20Votes("Bridged Token", "bNAT");

        bridgeSource = new CrossChainTokenBridge(address(tokenSource), validator);
        bridgeDest = new CrossChainTokenBridge(address(tokenDest), validator);

        tokenSource.mint(alice, 1000e18);

        vm.prank(alice);
        tokenSource.approve(address(bridgeSource), type(uint256).max);
    }

    function test_CrossChainLockAndMintCycle() public {
        // Alice locks 100 tokens on source chain for Bob on destination chain (Chain ID 42161)
        vm.prank(alice);
        bridgeSource.bridgeLock(bob, 100e18, 42161, 1);

        assertEq(tokenSource.balanceOf(address(bridgeSource)), 100e18);

        // Validator attests and mints 100 wrapped tokens to Bob on destination chain
        vm.prank(validator);
        bridgeDest.mintBridgedTokens(bob, 100e18, block.chainid, 1);

        assertEq(tokenDest.balanceOf(bob), 100e18);
    }

    function test_RevertIf_ReplayAttestation() public {
        vm.prank(validator);
        bridgeDest.mintBridgedTokens(bob, 50e18, 1, 999);

        // Attempting to replay same transferId
        vm.prank(validator);
        vm.expectRevert(CrossChainTokenBridge.AlreadyProcessed.selector);
        bridgeDest.mintBridgedTokens(bob, 50e18, 1, 999);
    }
}
