// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title HTLC (Hash Time-Locked Contract)
/// @notice Cryptographic conditional payment primitive for cross-chain atomic swaps
contract HTLC {
    event Lock(
        bytes32 indexed contractId,
        address indexed sender,
        address indexed receiver,
        uint256 amount,
        bytes32 hashlock,
        uint256 timelock
    );
    event Withdraw(bytes32 indexed contractId, bytes32 secret);
    event Refund(bytes32 indexed contractId);

    error ContractAlreadyExists();
    error ContractNotExists();
    error AlreadyWithdrawn();
    error AlreadyRefunded();
    error HashlockNotMatch();
    error TimelockNotExpired();
    error TimelockExpired();
    error NotReceiver();
    error NotSender();
    error TransferFailed();

    struct LockContract {
        address sender;
        address receiver;
        uint256 amount;
        bytes32 hashlock;
        uint256 timelock;
        bool withdrawn;
        bool refunded;
        bytes32 secret;
    }

    mapping(bytes32 => LockContract) public contracts;

    function lock(address receiver, bytes32 hashlock, uint256 timelock) external payable returns (bytes32 contractId) {
        require(msg.value > 0, "Zero amount");
        require(timelock > block.timestamp, "Timelock must be in future");

        contractId = keccak256(abi.encodePacked(msg.sender, receiver, msg.value, hashlock, timelock));
        if (contracts[contractId].sender != address(0)) revert ContractAlreadyExists();

        contracts[contractId] = LockContract({
            sender: msg.sender,
            receiver: receiver,
            amount: msg.value,
            hashlock: hashlock,
            timelock: timelock,
            withdrawn: false,
            refunded: false,
            secret: bytes32(0)
        });

        emit Lock(contractId, msg.sender, receiver, msg.value, hashlock, timelock);
    }

    function withdraw(bytes32 contractId, bytes32 secret) external {
        LockContract storage c = contracts[contractId];
        if (c.sender == address(0)) revert ContractNotExists();
        if (c.withdrawn) revert AlreadyWithdrawn();
        if (c.refunded) revert AlreadyRefunded();
        if (block.timestamp >= c.timelock) revert TimelockExpired();
        if (sha256(abi.encodePacked(secret)) != c.hashlock) revert HashlockNotMatch();

        c.secret = secret;
        c.withdrawn = true;

        (bool success,) = c.receiver.call{value: c.amount}("");
        if (!success) revert TransferFailed();

        emit Withdraw(contractId, secret);
    }

    function refund(bytes32 contractId) external {
        LockContract storage c = contracts[contractId];
        if (c.sender == address(0)) revert ContractNotExists();
        if (c.withdrawn) revert AlreadyWithdrawn();
        if (c.refunded) revert AlreadyRefunded();
        if (block.timestamp < c.timelock) revert TimelockNotExpired();

        c.refunded = true;

        (bool success,) = c.sender.call{value: c.amount}("");
        if (!success) revert TransferFailed();

        emit Refund(contractId);
    }
}
