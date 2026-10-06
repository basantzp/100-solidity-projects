// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title ConcentratedLiquidityPool
/// @notice Uniswap v3 inspired tick-range concentrated liquidity pool.
/// @dev Implements Q64.96 fixed-point sqrt price arithmetic and tick positions.
contract ConcentratedLiquidityPool {
    // --- Errors ---
    error InvalidTickRange();
    error ZeroLiquidity();
    error PriceOutOfBounds();
    error InsufficientOutput();
    error TransferFailed();

    // --- Constants ---
    uint256 internal constant Q96 = 2 ** 96;

    // --- Structs ---
    struct Position {
        uint128 liquidity;
        uint256 feeGrowthInside0Last;
        uint256 feeGrowthInside1Last;
        uint128 tokensOwed0;
        uint128 tokensOwed1;
    }

    struct Slot0 {
        uint160 sqrtPriceX96;
        int24 tick;
        bool unlocked;
    }

    // --- State Variables ---
    address public immutable token0;
    address public immutable token1;

    Slot0 public slot0;
    uint128 public liquidity;

    mapping(bytes32 => Position) public positions;
    mapping(int24 => int128) public tickLiquidityNet;

    event Mint(address indexed owner, int24 indexed tickLower, int24 indexed tickUpper, uint128 amount);
    event Swap(address indexed sender, address indexed recipient, int256 amount0, int256 amount1, uint160 sqrtPriceX96);

    constructor(address _token0, address _token1, uint160 _initialSqrtPriceX96, int24 _initialTick) {
        token0 = _token0;
        token1 = _token1;
        slot0 = Slot0({sqrtPriceX96: _initialSqrtPriceX96, tick: _initialTick, unlocked: true});
    }

    function getPositionKey(address owner, int24 tickLower, int24 tickUpper) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(owner, tickLower, tickUpper));
    }

    /// @notice Add concentrated liquidity within [tickLower, tickUpper]
    function mint(address recipient, int24 tickLower, int24 tickUpper, uint128 amount)
        external
        returns (uint256 amount0, uint256 amount1)
    {
        if (tickLower >= tickUpper) revert InvalidTickRange();
        if (amount == 0) revert ZeroLiquidity();

        bytes32 positionKey = getPositionKey(recipient, tickLower, tickUpper);
        Position storage pos = positions[positionKey];
        pos.liquidity += amount;

        // If current tick is within range, active pool liquidity increases
        if (slot0.tick >= tickLower && slot0.tick < tickUpper) {
            liquidity += amount;
        }

        tickLiquidityNet[tickLower] += int128(amount);
        tickLiquidityNet[tickUpper] -= int128(amount);

        // Required amounts: simplified proportional amounts for range
        amount0 = (uint256(amount) * Q96) / slot0.sqrtPriceX96;
        amount1 = (uint256(amount) * slot0.sqrtPriceX96) / Q96;

        _safeTransferFrom(token0, msg.sender, address(this), amount0);
        _safeTransferFrom(token1, msg.sender, address(this), amount1);

        emit Mint(recipient, tickLower, tickUpper, amount);
    }

    /// @notice Swap token0 for token1 along the concentrated liquidity curve
    function swapExact0For1(uint256 amount0In, address recipient) external returns (uint256 amount1Out) {
        if (amount0In == 0) revert InsufficientOutput();
        if (liquidity == 0) revert ZeroLiquidity();

        _safeTransferFrom(token0, msg.sender, address(this), amount0In);

        // Constant concentrated formula within current tick:
        // dy = L * d(sqrtP) = (amount0In * sqrtPriceX96^2) / (Q96^2)
        uint256 currentPrice = slot0.sqrtPriceX96;
        amount1Out = (amount0In * currentPrice) / Q96;

        // Price moves down with token0 inflow
        uint160 nextPrice = uint160(currentPrice - (currentPrice * amount0In) / (uint256(liquidity) * 10 + amount0In));
        slot0.sqrtPriceX96 = nextPrice;

        _safeTransfer(token1, recipient, amount1Out);

        emit Swap(msg.sender, recipient, int256(amount0In), -int256(amount1Out), nextPrice);
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
