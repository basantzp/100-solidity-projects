// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {CCIPCrossChainExecutor} from "../src/09_CrossChain/CCIPCrossChainExecutor.sol";

contract CCIPCrossChainExecutorTest is Test {
    CCIPCrossChainExecutor public executor;
    address public router = address(0xCC19);

    uint64 public sourceChainSelector = 16015286601757825753; // Ethereum Sepolia
    address public senderOnSource = address(0x5678);

    function setUp() public {
        executor = new CCIPCrossChainExecutor(router);
        executor.setSourceChainAllowed(sourceChainSelector, true);
        executor.setSenderAllowed(senderOnSource, true);
    }

    function test_CCIPReceiveExecution() public {
        CCIPCrossChainExecutor.EVMTokenAmount[] memory tokenAmounts = new CCIPCrossChainExecutor.EVMTokenAmount[](0);
        CCIPCrossChainExecutor.Any2EVMMessage memory msgPayload = CCIPCrossChainExecutor.Any2EVMMessage({
            messageId: keccak256("message-1"),
            sourceChainSelector: sourceChainSelector,
            sender: abi.encode(senderOnSource),
            data: abi.encode("PAYLOAD_DATA"),
            destTokenAmounts: tokenAmounts
        });

        vm.prank(router);
        executor.ccipReceive(msgPayload);
    }
}
