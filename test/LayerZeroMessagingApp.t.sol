// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {LayerZeroMessagingApp} from "../src/09_CrossChain/LayerZeroMessagingApp.sol";

contract LayerZeroMessagingAppTest is Test {
    LayerZeroMessagingApp public app;
    address public endpoint = address(0xEEEE);

    uint32 public srcEid = 30101; // Ethereum
    uint32 public dstEid = 30110; // Arbitrum

    bytes32 public peerRemote = bytes32(uint256(uint160(address(0x1234))));

    function setUp() public {
        app = new LayerZeroMessagingApp(endpoint);
        app.setTrustedRemote(srcEid, peerRemote, true);
    }

    function test_SendAndReceiveMessage() public {
        // Send message
        bytes memory payload = abi.encode("CROSS_CHAIN_HELLO");
        uint64 nonce = app.send(dstEid, peerRemote, payload);
        assertEq(nonce, 1);

        // Receive message from endpoint
        vm.prank(endpoint);
        app.lzReceive(srcEid, peerRemote, 1, payload);

        assertTrue(app.processedNonces(srcEid, 1));
    }
}
