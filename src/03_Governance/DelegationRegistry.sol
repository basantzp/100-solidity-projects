// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title DelegationRegistry
/// @notice Granular hierarchical rights delegation registry (Delegate.xyz style) supporting global, contract, and token-level delegations.
contract DelegationRegistry {
    // --- Events ---
    event DelegatedGlobal(address indexed delegator, address indexed delegate, bool enabled);
    event DelegatedContract(
        address indexed delegator, address indexed delegate, address indexed targetContract, bool enabled
    );
    event DelegatedToken(
        address indexed delegator,
        address indexed delegate,
        address indexed targetContract,
        uint256 tokenId,
        bool enabled
    );

    // delegator => delegate => isDelegated
    mapping(address => mapping(address => bool)) public globalDelegation;

    // delegator => delegate => targetContract => isDelegated
    mapping(address => mapping(address => mapping(address => bool))) public contractDelegation;

    // delegator => delegate => targetContract => tokenId => isDelegated
    mapping(address => mapping(address => mapping(address => mapping(uint256 => bool)))) public tokenDelegation;

    /// @notice Delegate all governance rights globally
    function delegateAll(address delegate, bool enabled) external {
        globalDelegation[msg.sender][delegate] = enabled;
        emit DelegatedGlobal(msg.sender, delegate, enabled);
    }

    /// @notice Delegate governance rights for a specific contract/collection
    function delegateForContract(address delegate, address targetContract, bool enabled) external {
        contractDelegation[msg.sender][delegate][targetContract] = enabled;
        emit DelegatedContract(msg.sender, delegate, targetContract, enabled);
    }

    /// @notice Delegate rights for a specific token ID
    function delegateForToken(address delegate, address targetContract, uint256 tokenId, bool enabled) external {
        tokenDelegation[msg.sender][delegate][targetContract][tokenId] = enabled;
        emit DelegatedToken(msg.sender, delegate, targetContract, tokenId, enabled);
    }

    /// @notice Checks if delegate is authorized for a specific token under delegator
    function checkDelegateForToken(address delegate, address delegator, address targetContract, uint256 tokenId)
        external
        view
        returns (bool)
    {
        if (globalDelegation[delegator][delegate]) return true;
        if (contractDelegation[delegator][delegate][targetContract]) return true;
        return tokenDelegation[delegator][delegate][targetContract][tokenId];
    }
}
