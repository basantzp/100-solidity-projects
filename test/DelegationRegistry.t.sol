// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {DelegationRegistry} from "../src/03_Governance/DelegationRegistry.sol";

contract DelegationRegistryTest is Test {
    DelegationRegistry public registry;

    address public alice = address(0xA11CE);
    address public delegateAddress = address(0xDE1E);
    address public nftContract = address(0xBEEF);

    function setUp() public {
        registry = new DelegationRegistry();
    }

    function test_GlobalAndTokenDelegations() public {
        // Initially not delegated
        assertFalse(registry.checkDelegateForToken(delegateAddress, alice, nftContract, 42));

        // Alice delegates specifically token 42
        vm.prank(alice);
        registry.delegateForToken(delegateAddress, nftContract, 42, true);

        assertTrue(registry.checkDelegateForToken(delegateAddress, alice, nftContract, 42));
        assertFalse(registry.checkDelegateForToken(delegateAddress, alice, nftContract, 99));

        // Alice delegates all globally
        vm.prank(alice);
        registry.delegateAll(delegateAddress, true);

        assertTrue(registry.checkDelegateForToken(delegateAddress, alice, nftContract, 99));
    }
}
