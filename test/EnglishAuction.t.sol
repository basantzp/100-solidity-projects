// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {EnglishAuction} from "../src/02_DeFi/EnglishAuction.sol";
import {ERC721NFT} from "../src/01_Tokens/ERC721NFT.sol";

contract MockEnglishNFT is ERC721NFT {
    constructor() ERC721NFT("English NFT", "ENFT") {}

    function mint(address to, uint256 id) external {
        _mint(to, id);
    }
}

contract EnglishAuctionTest is Test {
    MockEnglishNFT nft;
    EnglishAuction auction;

    address seller = address(0x10);
    address bidder1 = address(0x21);
    address bidder2 = address(0x22);

    function setUp() public {
        nft = new MockEnglishNFT();
        nft.mint(seller, 1);

        vm.prank(seller);
        auction = new EnglishAuction(nft, 1, 1 ether);

        vm.prank(seller);
        nft.approve(address(auction), 1);

        vm.deal(bidder1, 10 ether);
        vm.deal(bidder2, 10 ether);
    }

    function test_AuctionLifecycle() public {
        // Start auction for 1 day
        vm.prank(seller);
        auction.start(1 days);

        // Bidder 1 bids 2 ETH
        vm.prank(bidder1);
        auction.bid{value: 2 ether}();
        assertEq(auction.highestBidder(), bidder1);
        assertEq(auction.highestBid(), 2 ether);

        // Bidder 2 bids 3 ETH
        vm.prank(bidder2);
        auction.bid{value: 3 ether}();
        assertEq(auction.highestBidder(), bidder2);
        assertEq(auction.highestBid(), 3 ether);

        // Bidder 1 withdraws outbid funds (2 ETH)
        assertEq(auction.bids(bidder1), 2 ether);
        vm.prank(bidder1);
        auction.withdraw();
        assertEq(auction.bids(bidder1), 0);
        assertEq(bidder1.balance, 10 ether);

        // End auction after 1 day
        vm.warp(block.timestamp + 1 days);
        auction.end();

        assertEq(nft.ownerOf(1), bidder2);
        assertEq(seller.balance, 3 ether);
    }
}
