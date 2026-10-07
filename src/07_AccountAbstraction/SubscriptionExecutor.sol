// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title SubscriptionExecutor
/// @notice Automated recurring pull-payment subscription module for ERC-4337 smart accounts.
contract SubscriptionExecutor {
    // --- Errors ---
    error SubscriptionNotDue();
    error SubscriptionInactive();
    error Unauthorized();
    error TransferFailed();
    error ZeroAmount();

    // --- Events ---
    event SubscriptionCreated(
        bytes32 indexed subId, address indexed subscriber, address indexed recipient, uint256 rate, uint32 interval
    );
    event SubscriptionExecuted(bytes32 indexed subId, uint256 amountBilled, uint256 timestamp);
    event SubscriptionCancelled(bytes32 indexed subId);

    struct Subscription {
        address subscriber;
        address recipient;
        address token;
        uint256 rate;
        uint32 interval;
        uint256 lastBilled;
        bool active;
    }

    mapping(bytes32 => Subscription) public subscriptions;

    function createSubscription(address recipient, address token, uint256 rate, uint32 interval)
        external
        returns (bytes32 subId)
    {
        if (rate == 0) revert ZeroAmount();

        subId = keccak256(abi.encode(msg.sender, recipient, token, block.timestamp));
        subscriptions[subId] = Subscription({
            subscriber: msg.sender,
            recipient: recipient,
            token: token,
            rate: rate,
            interval: interval,
            lastBilled: block.timestamp,
            active: true
        });

        emit SubscriptionCreated(subId, msg.sender, recipient, rate, interval);
    }

    /// @notice Anyone / keeper triggers billing when due
    function executeBilling(bytes32 subId) external {
        Subscription storage sub = subscriptions[subId];
        if (!sub.active) revert SubscriptionInactive();
        if (block.timestamp < sub.lastBilled + sub.interval) revert SubscriptionNotDue();

        sub.lastBilled = block.timestamp;

        _safeTransferFrom(sub.token, sub.subscriber, sub.recipient, sub.rate);
        emit SubscriptionExecuted(subId, sub.rate, block.timestamp);
    }

    function cancelSubscription(bytes32 subId) external {
        Subscription storage sub = subscriptions[subId];
        if (msg.sender != sub.subscriber) revert Unauthorized();
        sub.active = false;
        emit SubscriptionCancelled(subId);
    }

    function _safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, amount));
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) revert TransferFailed();
    }
}
