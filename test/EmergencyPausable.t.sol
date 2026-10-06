// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {EmergencyPausable} from "../src/04_Security/EmergencyPausable.sol";

// Sample vault guarded by EmergencyPausable
contract VaultWithPause is EmergencyPausable {
    mapping(address => uint256) public deposits;

    function deposit() external payable whenNotPaused {
        deposits[msg.sender] += msg.value;
    }

    function emergencyWithdraw() external whenPaused {
        uint256 amount = deposits[msg.sender];
        deposits[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }
}

contract EmergencyPausableTest is Test {
    VaultWithPause public vault;
    address public alice = address(0xA11CE);

    function setUp() public {
        vault = new VaultWithPause();
        vm.deal(alice, 5 ether);
    }

    function test_DepositWhenNotPaused() public {
        vm.prank(alice);
        vault.deposit{value: 2 ether}();
        assertEq(vault.deposits(alice), 2 ether);
    }

    function test_PauseBlocksDeposit() public {
        vault.pause();
        assertTrue(vault.paused());

        vm.prank(alice);
        vm.expectRevert(EmergencyPausable.EnforcedPause.selector);
        vault.deposit{value: 1 ether}();
    }

    function test_UnpauseRestoresOperation() public {
        vault.pause();
        vault.unpause();

        vm.prank(alice);
        vault.deposit{value: 1 ether}();
        assertEq(vault.deposits(alice), 1 ether);
    }

    function test_RevertIf_UnauthorizedPauser() public {
        vm.prank(alice);
        vm.expectRevert(EmergencyPausable.UnauthorizedPauser.selector);
        vault.pause();
    }
}
