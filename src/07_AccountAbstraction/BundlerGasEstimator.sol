// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title BundlerGasEstimator
/// @notice Off-chain/on-chain simulation harness estimating ERC-4337 UserOperation validation and execution gas.
contract BundlerGasEstimator {
    struct UserOpSimulation {
        uint256 preVerificationGas;
        uint256 verificationGas;
        uint256 executionGas;
        bool executionSuccess;
    }

    /// @notice Simulates execution of arbitrary target call and measures exact gas consumed
    function estimateUserOpGas(address target, uint256 value, bytes calldata data)
        external
        returns (UserOpSimulation memory result)
    {
        // Base calldata / pre-verification gas estimation (16 gas per non-zero byte, 4 per zero)
        uint256 calldataGas = 21_000;
        for (uint256 i = 0; i < data.length; i++) {
            calldataGas += data[i] == 0 ? 4 : 16;
        }
        result.preVerificationGas = calldataGas;

        // Simulated validation gas
        result.verificationGas = 35_000;

        // Measure execution gas
        uint256 startGas = gasleft();
        (bool success,) = target.call{value: value}(data);
        uint256 gasUsed = startGas - gasleft();

        result.executionGas = gasUsed;
        result.executionSuccess = success;
    }
}
