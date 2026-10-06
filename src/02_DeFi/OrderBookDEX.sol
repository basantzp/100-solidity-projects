// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title OrderBookDEX
/// @notice On-chain limit order book matching and execution engine.
/// @dev Handles escrowed limit bids/asks and partial/full settlement.
contract OrderBookDEX {
    // --- Errors ---
    error ZeroAmount();
    error ZeroPrice();
    error OrderNotActive();
    error OrderAlreadyFilled();
    error Unauthorized();
    error TransferFailed();

    // --- Structs ---
    struct Order {
        uint256 id;
        address trader;
        bool isBuy; // true = Buy tokenB with tokenA, false = Sell tokenB for tokenA
        uint256 price; // Price of tokenB in terms of tokenA (scaled by 1e18)
        uint256 amount; // Total tokenB amount
        uint256 filled; // Filled tokenB amount
        bool active;
    }

    // --- State Variables ---
    address public immutable baseToken; // e.g. WETH (tokenB)
    address public immutable quoteToken; // e.g. USDC (tokenA)

    uint256 public nextOrderId;
    mapping(uint256 => Order) public orders;

    // --- Events ---
    event OrderPlaced(uint256 indexed orderId, address indexed trader, bool isBuy, uint256 price, uint256 amount);
    event OrderCancelled(uint256 indexed orderId);
    event OrderFilled(uint256 indexed orderId, address indexed taker, uint256 amountFilled, uint256 costQuote);

    constructor(address _baseToken, address _quoteToken) {
        baseToken = _baseToken;
        quoteToken = _quoteToken;
    }

    /// @notice Place a limit order on-chain
    function placeOrder(bool isBuy, uint256 price, uint256 amount) external returns (uint256 orderId) {
        if (price == 0) revert ZeroPrice();
        if (amount == 0) revert ZeroAmount();

        orderId = nextOrderId++;
        orders[orderId] = Order({
            id: orderId, trader: msg.sender, isBuy: isBuy, price: price, amount: amount, filled: 0, active: true
        });

        if (isBuy) {
            // Escrow quote tokens: cost = (amount * price) / 1e18
            uint256 quoteCost = (amount * price) / 1e18;
            _safeTransferFrom(quoteToken, msg.sender, address(this), quoteCost);
        } else {
            // Escrow base tokens: amount
            _safeTransferFrom(baseToken, msg.sender, address(this), amount);
        }

        emit OrderPlaced(orderId, msg.sender, isBuy, price, amount);
    }

    /// @notice Cancel an unfilled or partially filled limit order
    function cancelOrder(uint256 orderId) external {
        Order storage order = orders[orderId];
        if (!order.active) revert OrderNotActive();
        if (order.trader != msg.sender) revert Unauthorized();

        order.active = false;
        uint256 remaining = order.amount - order.filled;

        if (order.isBuy) {
            uint256 refundQuote = (remaining * order.price) / 1e18;
            if (refundQuote > 0) _safeTransfer(quoteToken, order.trader, refundQuote);
        } else {
            if (remaining > 0) _safeTransfer(baseToken, order.trader, remaining);
        }

        emit OrderCancelled(orderId);
    }

    /// @notice Taker fills a pending limit order
    function fillOrder(uint256 orderId, uint256 fillAmount) external {
        Order storage order = orders[orderId];
        if (!order.active) revert OrderNotActive();
        if (fillAmount == 0) revert ZeroAmount();

        uint256 remaining = order.amount - order.filled;
        if (fillAmount > remaining) {
            fillAmount = remaining;
        }

        order.filled += fillAmount;
        if (order.filled == order.amount) {
            order.active = false;
        }

        uint256 quoteCost = (fillAmount * order.price) / 1e18;

        if (order.isBuy) {
            // Maker deposited quote, wants base.
            // Taker provides base, receives escrowed quote.
            _safeTransferFrom(baseToken, msg.sender, order.trader, fillAmount);
            _safeTransfer(quoteToken, msg.sender, quoteCost);
        } else {
            // Maker deposited base, wants quote.
            // Taker provides quote, receives escrowed base.
            _safeTransferFrom(quoteToken, msg.sender, order.trader, quoteCost);
            _safeTransfer(baseToken, msg.sender, fillAmount);
        }

        emit OrderFilled(orderId, msg.sender, fillAmount, quoteCost);
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
