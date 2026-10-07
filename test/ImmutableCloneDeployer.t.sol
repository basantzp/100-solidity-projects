// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {ImmutableCloneDeployer} from "../src/06_Upgradeability/ImmutableCloneDeployer.sol";

contract LogicTarget {
    uint256 public value;

    function setValue(uint256 v) external {
        value = v;
    }
}

contract ImmutableCloneDeployerTest is Test {
    ImmutableCloneDeployer public deployer;
    LogicTarget public implementation;

    function setUp() public {
        deployer = new ImmutableCloneDeployer();
        implementation = new LogicTarget();
    }

    function test_CloneWithImmutableArgs() public {
        bytes memory immutableData = abi.encode(address(0x1234), uint256(999));
        address cloneInstance = deployer.clone(address(implementation), immutableData);

        assertTrue(cloneInstance != address(0));

        bytes memory readArgs = deployer.readImmutableArgument(cloneInstance, immutableData.length);
        assertEq(keccak256(readArgs), keccak256(immutableData));
    }
}
