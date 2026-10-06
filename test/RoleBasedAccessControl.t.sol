// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {RoleBasedAccessControl} from "../src/03_Governance/RoleBasedAccessControl.sol";

contract RoleBasedAccessControlTest is Test {
    RoleBasedAccessControl public rbac;
    address public admin = address(this);
    address public alice = address(0xA11CE);
    address public bob = address(0xB0B);

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    function setUp() public {
        rbac = new RoleBasedAccessControl();
    }

    function test_InitialAdminHasDefaultAdminRole() public {
        assertTrue(rbac.hasRole(rbac.DEFAULT_ADMIN_ROLE(), admin));
        assertFalse(rbac.hasRole(MINTER_ROLE, alice));
    }

    function test_GrantAndRevokeRole() public {
        rbac.grantRole(MINTER_ROLE, alice);
        assertTrue(rbac.hasRole(MINTER_ROLE, alice));

        rbac.revokeRole(MINTER_ROLE, alice);
        assertFalse(rbac.hasRole(MINTER_ROLE, alice));
    }

    function test_RenounceRole() public {
        rbac.grantRole(MINTER_ROLE, alice);

        vm.prank(alice);
        rbac.renounceRole(MINTER_ROLE);

        assertFalse(rbac.hasRole(MINTER_ROLE, alice));
    }

    function test_RevertIf_UnauthorizedGrant() public {
        bytes32 adminRole = rbac.DEFAULT_ADMIN_ROLE();
        vm.expectRevert(
            abi.encodeWithSelector(RoleBasedAccessControl.AccessControlUnauthorizedAccount.selector, alice, adminRole)
        );
        vm.prank(alice);
        rbac.grantRole(MINTER_ROLE, bob);
    }
}
