// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title VolatilityFeeHook
/// @notice Uniswap v4-inspired dynamic fee hook that adjusts swap fees based on realized volatility (LVR mitigation).
contract VolatilityFeeHook {
    // --- Errors ---
    error Unauthorized();
    error InvalidFeeRange();

    // --- Events ---
    event FeeUpdated(uint24 newFeeBps, uint256 volatilityMetric);
    event ObservationRecorded(uint256 timestamp, uint256 price);

    // --- State Variables ---
    address public immutable owner;
    uint24 public constant BASE_FEE_BPS = 30; // 0.30%
    uint24 public constant MAX_FEE_BPS = 200; // 2.00%
    uint24 public constant MIN_FEE_BPS = 10; // 0.10%

    uint256 public lastPrice;
    uint256 public lastTimestamp;
    uint24 public currentFeeBps;

    // Moving average of absolute price changes
    uint256 public volatilityAccumulator;
    uint256 public observationCount;

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    constructor() {
        owner = msg.sender;
        currentFeeBps = BASE_FEE_BPS;
    }

    /// @notice Records price and updates dynamic volatility fee before swap execution.
    /// @param currentPrice Current oracle/pool price in 18-decimal precision.
    /// @return feeBps The calculated dynamic fee in basis points.
    function beforeSwap(uint256 currentPrice) external returns (uint24 feeBps) {
        if (lastPrice > 0 && block.timestamp > lastTimestamp) {
            uint256 priceDiff = currentPrice > lastPrice ? currentPrice - lastPrice : lastPrice - currentPrice;

            uint256 returnDeltaBps = (priceDiff * 10_000) / lastPrice;

            // Exponential moving average update (decay 80% previous, 20% new)
            volatilityAccumulator = (volatilityAccumulator * 4 + returnDeltaBps) / 5;
            observationCount++;

            // Adjust fee dynamically: base fee + scaled volatility factor
            uint24 dynamicFee = BASE_FEE_BPS + uint24(volatilityAccumulator / 2);
            if (dynamicFee > MAX_FEE_BPS) dynamicFee = MAX_FEE_BPS;
            if (dynamicFee < MIN_FEE_BPS) dynamicFee = MIN_FEE_BPS;

            currentFeeBps = dynamicFee;
            emit FeeUpdated(dynamicFee, volatilityAccumulator);
        }

        lastPrice = currentPrice;
        lastTimestamp = block.timestamp;
        emit ObservationRecorded(block.timestamp, currentPrice);

        return currentFeeBps;
    }

    /// @notice Manual override of fee for emergency intervention
    function setStaticFee(uint24 newFeeBps) external onlyOwner {
        if (newFeeBps < MIN_FEE_BPS || newFeeBps > MAX_FEE_BPS) revert InvalidFeeRange();
        currentFeeBps = newFeeBps;
        emit FeeUpdated(newFeeBps, volatilityAccumulator);
    }
}
