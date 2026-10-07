// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {LowLevelDispatcher} from "../src/06_CancunEVM/LowLevelDispatcher.sol";

contract LowLevelDispatcherTest is Test {
    LowLevelDispatcher public dispatcher;

    function setUp() public {
        dispatcher = new LowLevelDispatcher();
    }

    function test_LowLevelDispatch() public {
        // Call getOwner() -> 0x893d20e8
        (bool success, bytes memory data) = address(dispatcher).call(abi.encodeWithSignature("getOwner()"));
        assertTrue(success);
        address owner = abi.decode(data, (address));
        assertEq(owner, address(this));

        // Call setVal(uint256) -> 0x5c975abb
        (bool setSuccess,) = address(dispatcher).call(abi.encodeWithSignature("setVal(uint256)", 9999));
        assertTrue(setSuccess);

        // Call getVal() -> 0xe2309a64
        (bool getSuccess, bytes memory valData) = address(dispatcher).call(abi.encodeWithSignature("getVal()"));
        assertTrue(getSuccess);
        uint256 val = abi.decode(valData, (uint256));
        assertEq(val, 9999);
    }
}
