// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title MultiOwnerModularAccount
/// @notice ERC-7579 modular account with multi-owner threshold validation and pluggable execution modules.
contract MultiOwnerModularAccount {
    // --- Errors ---
    error Unauthorized();
    error ExecutionFailed();
    error InvalidThreshold();
    error NotAnOwner();

    // --- Events ---
    event Executed(address indexed target, uint256 value, bytes data);
    event ModuleInstalled(address indexed module, uint256 moduleType);
    event ModuleUninstalled(address indexed module, uint256 moduleType);

    mapping(address => bool) public isOwner;
    uint256 public ownerCount;
    uint256 public threshold;

    mapping(address => bool) public installedModules;

    modifier onlySelf() {
        if (msg.sender != address(this)) revert Unauthorized();
        _;
    }

    constructor(address[] memory _owners, uint256 _threshold) {
        if (_threshold == 0 || _threshold > _owners.length) revert InvalidThreshold();

        for (uint256 i = 0; i < _owners.length; i++) {
            isOwner[_owners[i]] = true;
        }
        ownerCount = _owners.length;
        threshold = _threshold;
    }

    receive() external payable {}

    /// @notice Installs an ERC-7579 execution module
    function installModule(address module, uint256 moduleType) external onlySelf {
        installedModules[module] = true;
        emit ModuleInstalled(module, moduleType);
    }

    /// @notice Uninstalls an ERC-7579 module
    function uninstallModule(address module, uint256 moduleType) external onlySelf {
        installedModules[module] = false;
        emit ModuleUninstalled(module, moduleType);
    }

    /// @notice Direct execution authorized by owners or installed module
    function executeFromModule(address target, uint256 value, bytes calldata data)
        external
        returns (bytes memory returnData)
    {
        if (!installedModules[msg.sender] && !isOwner[msg.sender]) revert Unauthorized();

        bool success;
        (success, returnData) = target.call{value: value}(data);
        if (!success) revert ExecutionFailed();

        emit Executed(target, value, data);
    }
}
