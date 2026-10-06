// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title MinimalProxyFactory
/// @notice Gas-optimized EIP-1167 Minimal Proxy (Clones) deployer
contract MinimalProxyFactory {
    event ProxyCreated(address indexed proxy, address indexed implementation);

    error DeploymentFailed();

    /// @notice Deploys an EIP-1167 minimal clone pointing to `implementation`
    function clone(address implementation) external returns (address instance) {
        assembly {
            // Cleans the upper 96 bits of the implementation address
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        if (instance == address(0)) revert DeploymentFailed();
        emit ProxyCreated(instance, implementation);
    }

    /// @notice Deploys an EIP-1167 clone with deterministic address using CREATE2
    function cloneDeterministic(address implementation, bytes32 salt) external returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        if (instance == address(0)) revert DeploymentFailed();
        emit ProxyCreated(instance, implementation);
    }

    /// @notice Predicts the address of a deterministic clone
    function predictDeterministicAddress(address implementation, bytes32 salt, address deployer)
        public
        pure
        returns (address predicted)
    {
        bytes memory code = abi.encodePacked(
            hex"3d602d80600a3d3981f3363d3d373d3d3d363d73", bytes20(implementation), hex"5af43d82803e903d91602b57fd5bf3"
        );
        bytes32 initCodeHash = keccak256(code);
        predicted = address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, initCodeHash)))));
    }
}
