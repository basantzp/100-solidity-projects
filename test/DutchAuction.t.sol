// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {DutchAuction} from "../src/02_DeFi/DutchAuction.sol";
import {ERC721NFT} from "../src/01_Tokens/ERC721NFT.sol";

contract MockAuctionNFT is ERC721NFT {
    constructor() ERC721NFT("Auction NFT", "ANFT") {}

    function mint(address to, uint256 id) external {
        _mint(to, id);
    }
}

contract DutchAuctionTest is Test {
    MockAuctionNFT nft;
    DutchAuction auction;

    address seller = address(0x10);
    address buyer = address(0x20);

    uint256 startingPrice = 10 ether;
    uint256 discountRate = 1 ether / 100; // 0.01 ether per second
    uint256 duration = 700; // 700 seconds => discount = 7 ether => reservePrice = 3 ether

    function setUp() public {
        nft = new MockAuctionNFT();
        nft.mint(seller, 1);

        vm.prank(seller);
        auction = new DutchAuction(nft, 1, startingPrice, discountRate, duration);

        vm.prank(seller);
        nft.approve(address(auction), 1);

        vm.deal(buyer, 20 ether);
    }

    function test_PriceDecaysOverTime() public {
        assertEq(auction.getPrice(), startingPrice);

        vm.warp(block.timestamp + 100);
        assertEq(auction.getPrice(), startingPrice - (discountRate * 100));
    }

    function test_BuyWithRefund() public {
        vm.warp(block.timestamp + 200);
        uint256 price = auction.getPrice();

        uint256 buyerBalBefore = buyer.balance;
        uint256 sellerBalBefore = seller.balance;

        vm.prank(buyer);
        auction.buy{value: 10 ether}();

        assertEq(nft.ownerOf(1), buyer);
        assertEq(buyerBalBefore - buyer.balance, price); // exact price deducted (remainder refunded)
        assertEq(seller.balance - sellerBalBefore, price);
    }
}
