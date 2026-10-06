// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721NFT} from "../01_Tokens/ERC721NFT.sol";

/// @title EnglishAuction
/// @notice Ascending bid auction with pull-payment refund architecture to prevent Denial-of-Service attacks
contract EnglishAuction {
    event Bid(address indexed sender, uint256 amount);
    event Withdraw(address indexed bidder, uint256 amount);
    event End(address winner, uint256 amount);

    error AuctionNotStarted();
    error AuctionAlreadyStarted();
    error AuctionEnded();
    error BidTooLow(uint256 currentHighest);
    error NotSeller();
    error TransferFailed();

    ERC721NFT public immutable nft;
    uint256 public immutable nftId;
    address payable public immutable seller;

    uint256 public endAt;
    bool public started;
    bool public ended;

    address public highestBidder;
    uint256 public highestBid;

    // Pull-over-push refunds mapping
    mapping(address => uint256) public bids;

    constructor(ERC721NFT _nft, uint256 _nftId, uint256 _startingBid) {
        nft = _nft;
        nftId = _nftId;
        seller = payable(msg.sender);
        highestBid = _startingBid;
    }

    function start(uint256 duration) external {
        if (msg.sender != seller) revert NotSeller();
        if (started) revert AuctionAlreadyStarted();

        started = true;
        endAt = block.timestamp + duration;
        nft.transferFrom(msg.sender, address(this), nftId);
    }

    function bid() external payable {
        if (!started) revert AuctionNotStarted();
        if (block.timestamp >= endAt) revert AuctionEnded();
        if (msg.value <= highestBid) revert BidTooLow(highestBid);

        if (highestBidder != address(0)) {
            bids[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;

        emit Bid(msg.sender, msg.value);
    }

    function withdraw() external {
        uint256 bal = bids[msg.sender];
        bids[msg.sender] = 0;
        (bool success,) = msg.sender.call{value: bal}("");
        if (!success) revert TransferFailed();

        emit Withdraw(msg.sender, bal);
    }

    function end() external {
        if (!started) revert AuctionNotStarted();
        if (block.timestamp < endAt) revert AuctionEnded();
        if (ended) revert AuctionEnded();

        ended = true;
        if (highestBidder != address(0)) {
            nft.transferFrom(address(this), highestBidder, nftId);
            (bool success,) = seller.call{value: highestBid}("");
            if (!success) revert TransferFailed();
        } else {
            nft.transferFrom(address(this), seller, nftId);
        }

        emit End(highestBidder, highestBid);
    }
}
