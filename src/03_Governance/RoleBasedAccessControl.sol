// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title RoleBasedAccessControl (RBAC)
/// @notice Hierarchical role-based access control contract.
/// @dev Each role has an admin role that controls granting and revoking permissions.
contract RoleBasedAccessControl {
    // --- Errors ---
    error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);
    error AccessControlBadConfirmation();

    // --- Events ---
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    // --- Constants ---
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    // --- State Variables ---
    mapping(bytes32 => mapping(address => bool)) private _roles;
    mapping(bytes32 => bytes32) private _roleAdmins;

    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role][account];
    }

    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roleAdmins[role];
    }

    function grantRole(bytes32 role, address account) public onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    function renounceRole(bytes32 role) public {
        _revokeRole(role, msg.sender);
    }

    function setRoleAdmin(bytes32 role, bytes32 adminRole) public onlyRole(getRoleAdmin(role)) {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roleAdmins[role] = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _checkRole(bytes32 role) internal view {
        if (!hasRole(role, msg.sender)) {
            revert AccessControlUnauthorizedAccount(msg.sender, role);
        }
    }

    function _grantRole(bytes32 role, address account) internal {
        if (!_roles[role][account]) {
            _roles[role][account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    function _revokeRole(bytes32 role, address account) internal {
        if (_roles[role][account]) {
            _roles[role][account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }
}
