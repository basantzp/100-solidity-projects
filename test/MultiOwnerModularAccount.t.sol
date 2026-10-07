// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {MultiOwnerModularAccount} from "../src/07_AccountAbstraction/MultiOwnerModularAccount.sol";

contract MockTarget {
    uint256 public value;

    function setVal(uint256 v) external {
        value = v;
    }
}

contract MultiOwnerModularAccountTest is Test {
    MultiOwnerModularAccount public account;
    MockTarget public target;

    address public owner1 = address(0x111);
    address public owner2 = address(0x222);

    function setUp() public {
        address[] memory owners = new address[](2);
        owners[0] = owner1;
        owners[1] = owner2;

        account = new MultiOwnerModularAccount(owners, 2);
        target = new MockTarget();
    }

    function test_OwnerCanExecuteCall() public {
        vm.prank(owner1);
        bytes memory data = abi.encodeWithSignature("setVal(uint256)", 777);
        account.executeFromModule(address(target), 0, data);

        assertEq(target.value(), 777);
    }
}
