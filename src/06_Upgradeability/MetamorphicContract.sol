// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title MetamorphicContract
/// @notice CREATE2 deterministic deployment factory for reproducible contract addresses.
contract MetamorphicContract {
    // --- Errors ---
    error DeploymentFailed();
    error TargetAlreadyDeployed();

    // --- Events ---
    event Deployed(address indexed deployedAddress, bytes32 indexed salt);

    /// @notice Computes deterministic CREATE2 address
    function computeAddress(bytes32 salt, bytes memory bytecode) public view returns (address) {
        bytes32 codeHash = keccak256(bytecode);
        return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, codeHash)))));
    }

    /// @notice Deploys arbitrary bytecode using CREATE2
    function deploy(bytes32 salt, bytes memory bytecode) external returns (address deployedAddress) {
        assembly {
            deployedAddress := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        if (deployedAddress == address(0)) revert DeploymentFailed();

        emit Deployed(deployedAddress, salt);
    }
}
