// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title SessionKeyPlugin
/// @notice Granular scoped session keys for smart accounts (ERC-7579 modular key validator).
/// @dev Restricts delegated keys by target contract, function selector, spending quota, and expiration.
contract SessionKeyPlugin {
    // --- Errors ---
    error Unauthorized();
    error SessionExpired();
    error TargetNotAllowed();
    error SelectorNotAllowed();
    error ExceedsSpendLimit();
    error SessionKeyInactive();
    error ExecutionFailed();

    // --- Structs ---
    struct SessionConfig {
        address allowedTarget;
        bytes4 allowedSelector;
        uint256 maxSpend;
        uint256 totalSpent;
        uint256 validUntil;
        bool active;
    }

    address public owner;
    // session key address => session config
    mapping(address => SessionConfig) public sessionKeys;

    event SessionKeyAdded(address indexed sessionKey, address indexed target, bytes4 selector, uint256 validUntil);
    event SessionKeyRevoked(address indexed sessionKey);
    event SessionExecuted(address indexed sessionKey, address indexed target, uint256 value);

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {}

    function addSessionKey(address key, address target, bytes4 selector, uint256 maxSpend, uint256 validUntil)
        external
        onlyOwner
    {
        sessionKeys[key] = SessionConfig({
            allowedTarget: target,
            allowedSelector: selector,
            maxSpend: maxSpend,
            totalSpent: 0,
            validUntil: validUntil,
            active: true
        });

        emit SessionKeyAdded(key, target, selector, validUntil);
    }

    function revokeSessionKey(address key) external onlyOwner {
        sessionKeys[key].active = false;
        emit SessionKeyRevoked(key);
    }

    /// @notice Execute call using authorized scoped session key
    function executeWithSessionKey(address target, uint256 value, bytes calldata data)
        external
        payable
        returns (bytes memory result)
    {
        SessionConfig storage config = sessionKeys[msg.sender];
        if (!config.active) revert SessionKeyInactive();
        if (block.timestamp > config.validUntil) revert SessionExpired();
        if (target != config.allowedTarget) revert TargetNotAllowed();
        if (bytes4(data[0:4]) != config.allowedSelector) revert SelectorNotAllowed();

        if (value > 0) {
            if (config.totalSpent + value > config.maxSpend) revert ExceedsSpendLimit();
            config.totalSpent += value;
        }

        bool success;
        (success, result) = target.call{value: value}(data);
        if (!success) revert ExecutionFailed();

        emit SessionExecuted(msg.sender, target, value);
    }
}
