// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title TransientFeeCalculator
/// @notice EIP-1153 transient storage (tstore/tload) fee accumulator for zero-SSTORE intra-transaction routing.
/// @dev Transient storage automatically clears at the end of the transaction with 0 gas teardown overhead.
contract TransientFeeCalculator {
    // --- Errors ---
    error ZeroAmount();
    error TransferFailed();

    event TransientFeeRecorded(address indexed token, uint256 fee, uint256 currentAccumulated);
    event TransientFeeSettled(address indexed token, address indexed beneficiary, uint256 totalSettled);

    function _tokenSlot(address token) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("transient.fee.slot", token));
    }

    /// @notice Accumulate fee into EIP-1153 transient memory
    function recordFee(address token, uint256 fee) external {
        if (fee == 0) revert ZeroAmount();

        bytes32 slot = _tokenSlot(token);
        uint256 current;
        assembly {
            current := tload(slot)
            current := add(current, fee)
            tstore(slot, current)
        }

        emit TransientFeeRecorded(token, fee, current);
    }

    /// @notice Read current accumulated fee from transient storage
    function getTransientFee(address token) public view returns (uint256 fee) {
        bytes32 slot = _tokenSlot(token);
        assembly {
            fee := tload(slot)
        }
    }

    /// @notice Settle accumulated transient fee in a single transfer, clearing transient register
    function settleFee(address token, address beneficiary) external returns (uint256 settled) {
        bytes32 slot = _tokenSlot(token);
        assembly {
            settled := tload(slot)
            tstore(slot, 0)
        }

        if (settled > 0) {
            (bool success, bytes memory data) =
                token.call(abi.encodeWithSignature("transfer(address,uint256)", beneficiary, settled));
            if (!success || (data.length != 0 && !abi.decode(data, (bool)))) revert TransferFailed();
        }

        emit TransientFeeSettled(token, beneficiary, settled);
    }
}
