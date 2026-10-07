// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title ImmutableCloneDeployer
/// @notice ERC-3448 style clone factory that appends immutable arguments directly to clone runtime bytecode.
contract ImmutableCloneDeployer {
    // --- Errors ---
    error DeploymentFailed();

    // --- Events ---
    event CloneWithImmutableArgsCreated(address indexed clone, address indexed implementation, bytes data);

    /// @notice Deploys a minimal clone with immutable arguments appended to runtime bytecode
    function clone(address implementation, bytes memory data) external returns (address instance) {
        bytes memory runtime = abi.encodePacked(
            hex"363d3d373d3d3d363d73", bytes20(implementation), hex"5af43d82803e903d91602b57fd5bf3", data
        );

        bytes memory creationCode = abi.encodePacked(hex"61", uint16(runtime.length), hex"3d81600a3d39f3", runtime);

        assembly {
            instance := create(0, add(creationCode, 0x20), mload(creationCode))
        }
        if (instance == address(0)) revert DeploymentFailed();

        emit CloneWithImmutableArgsCreated(instance, implementation, data);
    }

    /// @notice Helper to read immutable argument appended at end of an address's runtime code
    function readImmutableArgument(address target, uint256 argLength) external view returns (bytes memory args) {
        args = new bytes(argLength);
        assembly {
            let codeSz := extcodesize(target)
            let offset := sub(codeSz, argLength)
            extcodecopy(target, add(args, 0x20), offset, argLength)
        }
    }
}
