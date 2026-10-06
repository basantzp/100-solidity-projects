// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TimelockController
/// @notice Time-delayed transaction execution mechanism for governance proposals
contract TimelockController {
    event Queued(bytes32 indexed txHash, address indexed target, uint256 value, bytes data, uint256 eta);
    event Executed(bytes32 indexed txHash, address indexed target, uint256 value, bytes data);
    event Cancelled(bytes32 indexed txHash);

    error NotAdmin();
    error DelayTooShort(uint256 delay, uint256 minDelay);
    error DelayTooLong(uint256 delay, uint256 maxDelay);
    error TxAlreadyQueued(bytes32 txHash);
    error TxNotQueued(bytes32 txHash);
    error TimeNotReached(uint256 currentTimestamp, uint256 eta);
    error TxExpired(uint256 currentTimestamp, uint256 expiration);
    error ExecutionFailed();

    uint256 public constant MIN_DELAY = 1 days;
    uint256 public constant MAX_DELAY = 30 days;
    uint256 public constant GRACE_PERIOD = 14 days;

    address public admin;
    uint256 public delay;

    // txHash => isQueued
    mapping(bytes32 => bool) public isQueued;

    modifier onlyAdmin() {
        if (msg.sender != admin) revert NotAdmin();
        _;
    }

    constructor(uint256 _delay) {
        if (_delay < MIN_DELAY) revert DelayTooShort(_delay, MIN_DELAY);
        if (_delay > MAX_DELAY) revert DelayTooLong(_delay, MAX_DELAY);

        admin = msg.sender;
        delay = _delay;
    }

    receive() external payable {}

    function getTxHash(address target, uint256 value, bytes memory data, uint256 eta) public pure returns (bytes32) {
        return keccak256(abi.encode(target, value, data, eta));
    }

    function queue(address target, uint256 value, bytes memory data, uint256 eta)
        external
        onlyAdmin
        returns (bytes32 txHash)
    {
        if (eta < block.timestamp + delay) revert DelayTooShort(eta - block.timestamp, delay);

        txHash = getTxHash(target, value, data, eta);
        if (isQueued[txHash]) revert TxAlreadyQueued(txHash);

        isQueued[txHash] = true;
        emit Queued(txHash, target, value, data, eta);
    }

    function execute(address target, uint256 value, bytes memory data, uint256 eta)
        external
        payable
        onlyAdmin
        returns (bytes memory)
    {
        bytes32 txHash = getTxHash(target, value, data, eta);
        if (!isQueued[txHash]) revert TxNotQueued(txHash);
        if (block.timestamp < eta) revert TimeNotReached(block.timestamp, eta);
        if (block.timestamp > eta + GRACE_PERIOD) revert TxExpired(block.timestamp, eta + GRACE_PERIOD);

        isQueued[txHash] = false;

        (bool success, bytes memory returnData) = target.call{value: value}(data);
        if (!success) revert ExecutionFailed();

        emit Executed(txHash, target, value, data);
        return returnData;
    }

    function cancel(bytes32 txHash) external onlyAdmin {
        if (!isQueued[txHash]) revert TxNotQueued(txHash);
        isQueued[txHash] = false;
        emit Cancelled(txHash);
    }
}
