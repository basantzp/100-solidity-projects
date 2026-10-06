// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {ERC721NFT} from "../src/01_Tokens/ERC721NFT.sol";

contract MockNFT is ERC721NFT {
    constructor() ERC721NFT("Mock NFT", "MNFT") {
        _setDefaultRoyalty(msg.sender, 500); // 5% royalty
    }

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }
}

contract ERC721NFTTest is Test {
    MockNFT nft;
    address alice = address(0x1);
    address bob = address(0x2);

    function setUp() public {
        nft = new MockNFT();
        nft.mint(alice, 1);
    }

    function test_OwnerOfAndBalanceOf() public view {
        assertEq(nft.ownerOf(1), alice);
        assertEq(nft.balanceOf(alice), 1);
        assertEq(nft.balanceOf(bob), 0);
    }

    function test_Transfer() public {
        vm.prank(alice);
        nft.transferFrom(alice, bob, 1);

        assertEq(nft.ownerOf(1), bob);
        assertEq(nft.balanceOf(alice), 0);
        assertEq(nft.balanceOf(bob), 1);
    }

    function test_RoyaltyInfo() public view {
        (address receiver, uint256 royaltyAmount) = nft.royaltyInfo(1, 100 ether);
        assertEq(receiver, address(this));
        assertEq(royaltyAmount, 5 ether); // 5% of 100 ETH
    }

    function test_RevertIf_NotApproved() public {
        vm.prank(bob);
        vm.expectRevert(ERC721NFT.NotOwnerOrApproved.selector);
        nft.transferFrom(alice, bob, 1);
    }
}
