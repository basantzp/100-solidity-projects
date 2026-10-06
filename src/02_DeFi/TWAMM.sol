// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title TWAMM (Time-Weighted Automated Market Maker)
/// @notice Paradigm-inspired order slicing engine that executes large orders over time to minimize price impact and MEV.
contract TWAMM {
    // --- Errors ---
    error ZeroAmount();
    error InvalidBlockRange();
    error OrderNotActive();
    error Unauthorized();
    error TransferFailed();

    // --- Structs ---
    struct LongTermOrder {
        uint256 id;
        address owner;
        bool sellToken0; // true = sell token0 for token1, false = sell token1 for token0
        uint256 totalAmount;
        uint256 startBlock;
        uint256 endBlock;
        uint256 saleRate; // amount per block
        uint256 lastClaimBlock;
        uint256 claimedProceeds;
        bool active;
    }

    // --- State Variables ---
    address public immutable token0;
    address public immutable token1;

    // Standard AMM reserves
    uint256 public reserve0;
    uint256 public reserve1;

    uint256 public nextOrderId;
    mapping(uint256 => LongTermOrder) public orders;

    // --- Events ---
    event OrderCreated(
        uint256 indexed orderId, address indexed owner, bool sellToken0, uint256 totalAmount, uint256 duration
    );
    event ProceedsClaimed(uint256 indexed orderId, address indexed owner, uint256 proceeds);
    event OrderCancelled(uint256 indexed orderId, uint256 refundAmount);

    constructor(address _token0, address _token1, uint256 _initialReserve0, uint256 _initialReserve1) {
        token0 = _token0;
        token1 = _token1;
        reserve0 = _initialReserve0;
        reserve1 = _initialReserve1;
    }

    /// @notice Submit a long-term order to be sliced across durationInBlocks
    function submitLongTermOrder(bool sellToken0, uint256 amount, uint256 durationInBlocks)
        external
        returns (uint256 orderId)
    {
        if (amount == 0) revert ZeroAmount();
        if (durationInBlocks == 0) revert InvalidBlockRange();

        address sellToken = sellToken0 ? token0 : token1;
        _safeTransferFrom(sellToken, msg.sender, address(this), amount);

        orderId = nextOrderId++;
        uint256 start = block.number;
        uint256 end = start + durationInBlocks;
        uint256 rate = amount / durationInBlocks;

        orders[orderId] = LongTermOrder({
            id: orderId,
            owner: msg.sender,
            sellToken0: sellToken0,
            totalAmount: amount,
            startBlock: start,
            endBlock: end,
            saleRate: rate,
            lastClaimBlock: start,
            claimedProceeds: 0,
            active: true
        });

        emit OrderCreated(orderId, msg.sender, sellToken0, amount, durationInBlocks);
    }

    /// @notice Claim proceeds accumulated by the sliced execution up to current block
    function claimProceeds(uint256 orderId) external returns (uint256 proceeds) {
        LongTermOrder storage order = orders[orderId];
        if (!order.active && order.lastClaimBlock >= order.endBlock) revert OrderNotActive();
        if (order.owner != msg.sender) revert Unauthorized();

        uint256 current = block.number > order.endBlock ? order.endBlock : block.number;
        if (current <= order.lastClaimBlock) return 0;

        uint256 blocksExecuted = current - order.lastClaimBlock;
        uint256 amountSold = blocksExecuted * order.saleRate;

        // Calculate output based on AMM ratio
        if (order.sellToken0) {
            proceeds = (amountSold * reserve1) / (reserve0 + amountSold);
            reserve0 += amountSold;
            reserve1 -= proceeds;
            _safeTransfer(token1, order.owner, proceeds);
        } else {
            proceeds = (amountSold * reserve0) / (reserve1 + amountSold);
            reserve1 += amountSold;
            reserve0 -= proceeds;
            _safeTransfer(token0, order.owner, proceeds);
        }

        order.lastClaimBlock = current;
        order.claimedProceeds += proceeds;

        if (current >= order.endBlock) {
            order.active = false;
        }

        emit ProceedsClaimed(orderId, msg.sender, proceeds);
    }

    /// @notice Cancel remaining unsliced portion of order and refund
    function cancelOrder(uint256 orderId) external {
        LongTermOrder storage order = orders[orderId];
        if (!order.active) revert OrderNotActive();
        if (order.owner != msg.sender) revert Unauthorized();

        order.active = false;
        uint256 current = block.number > order.endBlock ? order.endBlock : block.number;
        uint256 blocksRemaining = order.endBlock > current ? order.endBlock - current : 0;
        uint256 refundAmount = blocksRemaining * order.saleRate;

        if (refundAmount > 0) {
            address sellToken = order.sellToken0 ? token0 : token1;
            _safeTransfer(sellToken, order.owner, refundAmount);
        }

        emit OrderCancelled(orderId, refundAmount);
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
