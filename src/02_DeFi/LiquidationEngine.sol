// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title LiquidationEngine
/// @notice Dutch auction collateral liquidation engine for underwater debt resolution (Maker/Compound style).
contract LiquidationEngine {
    // --- Errors ---
    error PositionHealthy();
    error AuctionNotActive();
    error AuctionExpired();
    error InsufficientPayment();
    error TransferFailed();
    error ZeroAmount();

    // --- Events ---
    event AuctionStarted(
        uint256 indexed auctionId, address indexed borrower, uint256 debtToCover, uint256 collateralAvailable
    );
    event AuctionSettled(
        uint256 indexed auctionId, address indexed liquidator, uint256 debtRepaid, uint256 collateralClaimed
    );

    struct Auction {
        address borrower;
        address collateralToken;
        address debtToken;
        uint256 debtAmount;
        uint256 collateralAmount;
        uint256 startPrice; // 18 decimals (debt per collateral)
        uint256 floorPrice; // 18 decimals
        uint256 startTime;
        uint256 duration;
        bool settled;
    }

    uint256 public nextAuctionId = 1;
    mapping(uint256 => Auction) public auctions;

    /// @notice Initiates a Dutch liquidation auction for an underwater position
    function startAuction(
        address borrower,
        address collateralToken,
        address debtToken,
        uint256 debtAmount,
        uint256 collateralAmount,
        uint256 startPrice,
        uint256 floorPrice,
        uint256 duration
    ) external returns (uint256 auctionId) {
        if (debtAmount == 0 || collateralAmount == 0) revert ZeroAmount();

        auctionId = nextAuctionId++;
        auctions[auctionId] = Auction({
            borrower: borrower,
            collateralToken: collateralToken,
            debtToken: debtToken,
            debtAmount: debtAmount,
            collateralAmount: collateralAmount,
            startPrice: startPrice,
            floorPrice: floorPrice,
            startTime: block.timestamp,
            duration: duration,
            settled: false
        });

        // Pull collateral into liquidation escrow
        _safeTransferFrom(collateralToken, msg.sender, address(this), collateralAmount);

        emit AuctionStarted(auctionId, borrower, debtAmount, collateralAmount);
    }

    /// @notice Calculates current auction price per collateral unit based on linear decay
    function getCurrentPrice(uint256 auctionId) public view returns (uint256) {
        Auction storage a = auctions[auctionId];
        if (a.settled) revert AuctionNotActive();

        uint256 elapsed = block.timestamp - a.startTime;
        if (elapsed >= a.duration) {
            return a.floorPrice;
        }

        uint256 priceDrop = ((a.startPrice - a.floorPrice) * elapsed) / a.duration;
        return a.startPrice - priceDrop;
    }

    /// @notice Liquidator repays debt and acquires discounted collateral at current Dutch price
    function take(uint256 auctionId, uint256 maxDebtToRepay) external returns (uint256 collateralPurchased) {
        Auction storage a = auctions[auctionId];
        if (a.settled) revert AuctionNotActive();

        uint256 price = getCurrentPrice(auctionId);
        uint256 debtToRepay = maxDebtToRepay > a.debtAmount ? a.debtAmount : maxDebtToRepay;

        // collateralPurchased = debtToRepay * 1e18 / price
        collateralPurchased = (debtToRepay * 1e18) / price;
        if (collateralPurchased > a.collateralAmount) {
            collateralPurchased = a.collateralAmount;
            debtToRepay = (collateralPurchased * price) / 1e18;
        }

        a.debtAmount -= debtToRepay;
        a.collateralAmount -= collateralPurchased;

        if (a.debtAmount == 0 || a.collateralAmount == 0) {
            a.settled = true;
            // Refund remaining collateral to borrower if debt is fully cleared
            if (a.collateralAmount > 0) {
                uint256 surplus = a.collateralAmount;
                a.collateralAmount = 0;
                _safeTransfer(a.collateralToken, a.borrower, surplus);
            }
        }

        // Pull debt tokens from liquidator to burner/lender
        _safeTransferFrom(a.debtToken, msg.sender, address(this), debtToRepay);
        // Send discounted collateral to liquidator
        _safeTransfer(a.collateralToken, msg.sender, collateralPurchased);

        emit AuctionSettled(auctionId, msg.sender, debtToRepay, collateralPurchased);
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
