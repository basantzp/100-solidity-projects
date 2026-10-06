// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721NFT} from "../01_Tokens/ERC721NFT.sol";

/// @title DutchAuction
/// @notice Descending price auction where the purchase price linearly decreases over time
contract DutchAuction {
    event Bought(address indexed buyer, uint256 price);

    error AuctionEnded();
    error InsufficientPayment(uint256 sent, uint256 required);
    error TransferFailed();

    ERC721NFT public immutable nft;
    uint256 public immutable nftId;
    address payable public immutable seller;

    uint256 public immutable startingPrice;
    uint256 public immutable reservePrice;
    uint256 public immutable startAt;
    uint256 public immutable expiresAt;
    uint256 public immutable discountRate;

    bool public isSold;

    constructor(ERC721NFT _nft, uint256 _nftId, uint256 _startingPrice, uint256 _discountRate, uint256 _duration) {
        seller = payable(msg.sender);
        nft = _nft;
        nftId = _nftId;
        startingPrice = _startingPrice;
        discountRate = _discountRate;
        startAt = block.timestamp;
        expiresAt = block.timestamp + _duration;

        require(_startingPrice >= _discountRate * _duration, "Starting price too low for discount rate");
        reservePrice = _startingPrice - (_discountRate * _duration);
    }

    function getPrice() public view returns (uint256) {
        if (block.timestamp >= expiresAt) return reservePrice;
        uint256 timeElapsed = block.timestamp - startAt;
        uint256 discount = discountRate * timeElapsed;
        return startingPrice - discount;
    }

    function buy() external payable {
        if (isSold || block.timestamp > expiresAt) revert AuctionEnded();

        uint256 price = getPrice();
        if (msg.value < price) revert InsufficientPayment(msg.value, price);

        isSold = true;
        nft.transferFrom(seller, msg.sender, nftId);

        uint256 refund = msg.value - price;
        if (refund > 0) {
            (bool successRefund,) = msg.sender.call{value: refund}("");
            if (!successRefund) revert TransferFailed();
        }

        (bool successSeller,) = seller.call{value: price}("");
        if (!successSeller) revert TransferFailed();

        emit Bought(msg.sender, price);
    }
}
