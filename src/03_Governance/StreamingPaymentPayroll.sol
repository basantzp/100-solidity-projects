// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title StreamingPaymentPayroll
/// @notice Continuous real-time linear token streaming primitive for second-by-second salary distributions.
contract StreamingPaymentPayroll {
    // --- Errors ---
    error ZeroDeposit();
    error InvalidTimeFrame();
    error StreamNotActive();
    error InsufficientStreamBalance();
    error Unauthorized();
    error TransferFailed();

    // --- Structs ---
    struct Stream {
        address sender;
        address recipient;
        address token;
        uint256 deposit;
        uint256 ratePerSecond;
        uint256 startTime;
        uint256 stopTime;
        uint256 withdrawnAmount;
        bool active;
    }

    uint256 public nextStreamId;
    mapping(uint256 => Stream) public streams;

    event StreamCreated(uint256 indexed streamId, address indexed sender, address indexed recipient, uint256 deposit);
    event TokensWithdrawn(uint256 indexed streamId, address indexed recipient, uint256 amount);
    event StreamCancelled(uint256 indexed streamId, uint256 senderRefund, uint256 recipientPayout);

    function createStream(address recipient, address token, uint256 deposit, uint256 startTime, uint256 stopTime)
        external
        returns (uint256 streamId)
    {
        if (deposit == 0) revert ZeroDeposit();
        if (startTime < block.timestamp || stopTime <= startTime) revert InvalidTimeFrame();

        uint256 duration = stopTime - startTime;
        if (deposit < duration) revert ZeroDeposit();

        uint256 rate = deposit / duration;

        _safeTransferFrom(token, msg.sender, address(this), deposit);

        streamId = nextStreamId++;
        streams[streamId] = Stream({
            sender: msg.sender,
            recipient: recipient,
            token: token,
            deposit: deposit,
            ratePerSecond: rate,
            startTime: startTime,
            stopTime: stopTime,
            withdrawnAmount: 0,
            active: true
        });

        emit StreamCreated(streamId, msg.sender, recipient, deposit);
    }

    /// @notice Total vested tokens streamed to recipient up to now
    function streamedBalance(uint256 streamId) public view returns (uint256) {
        Stream storage s = streams[streamId];
        if (block.timestamp <= s.startTime) return 0;
        if (block.timestamp >= s.stopTime) return s.deposit;

        uint256 elapsed = block.timestamp - s.startTime;
        return elapsed * s.ratePerSecond;
    }

    /// @notice Available unwithdrawn vested tokens
    function availableToWithdraw(uint256 streamId) public view returns (uint256) {
        Stream storage s = streams[streamId];
        uint256 vested = streamedBalance(streamId);
        return vested > s.withdrawnAmount ? vested - s.withdrawnAmount : 0;
    }

    function withdrawFromStream(uint256 streamId, uint256 amount) external {
        Stream storage s = streams[streamId];
        if (!s.active) revert StreamNotActive();
        if (msg.sender != s.recipient) revert Unauthorized();

        uint256 available = availableToWithdraw(streamId);
        if (amount > available) revert InsufficientStreamBalance();

        s.withdrawnAmount += amount;
        _safeTransfer(s.token, s.recipient, amount);

        emit TokensWithdrawn(streamId, s.recipient, amount);
    }

    function cancelStream(uint256 streamId) external {
        Stream storage s = streams[streamId];
        if (!s.active) revert StreamNotActive();
        if (msg.sender != s.sender && msg.sender != s.recipient) revert Unauthorized();

        s.active = false;
        uint256 vested = streamedBalance(streamId);
        uint256 recipientPayout = vested > s.withdrawnAmount ? vested - s.withdrawnAmount : 0;
        uint256 senderRefund = s.deposit - vested;

        if (recipientPayout > 0) {
            _safeTransfer(s.token, s.recipient, recipientPayout);
        }
        if (senderRefund > 0) {
            _safeTransfer(s.token, s.sender, senderRefund);
        }

        emit StreamCancelled(streamId, senderRefund, recipientPayout);
    }

    function _safeTransfer(address token, address to, uint256 amount) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSignature("transfer(address,uint256)", to, amount));
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) revert TransferFailed();
    }

    function _safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, amount));
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) revert TransferFailed();
    }
}
