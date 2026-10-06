// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {ERC721A} from "../src/01_Tokens/ERC721A.sol";

contract ERC721ATest is Test {
    ERC721A public nft;
    address public alice = address(0xA11CE);
    address public bob = address(0xB0B);

    function setUp() public {
        nft = new ERC721A("Batch NFT", "BNFT");
    }

    function test_BatchMintGasOptimization() public {
        // Minting 5 tokens in one batch
        uint256 gasBefore = gasleft();
        nft.mint(alice, 5);
        uint256 gasUsed = gasBefore - gasleft();

        // Mint gas should be extremely compact (< 120k gas for 5 tokens vs 250k+ in traditional ERC721)
        assertLt(gasUsed, 120000);
        assertEq(nft.balanceOf(alice), 5);
        assertEq(nft.totalSupply(), 5);

        // Every token in the batch resolves to Alice
        for (uint256 i = 0; i < 5; i++) {
            assertEq(nft.ownerOf(i), alice);
        }
    }

    function test_TransferMiddleTokenMaintainsContinuity() public {
        nft.mint(alice, 5); // Alice owns 0, 1, 2, 3, 4

        // Alice transfers token 2 to Bob
        vm.prank(alice);
        nft.transferFrom(alice, bob, 2);

        assertEq(nft.ownerOf(0), alice);
        assertEq(nft.ownerOf(1), alice);
        assertEq(nft.ownerOf(2), bob);
        assertEq(nft.ownerOf(3), alice); // Correctly retained by Alice!
        assertEq(nft.ownerOf(4), alice);

        assertEq(nft.balanceOf(alice), 4);
        assertEq(nft.balanceOf(bob), 1);
    }

    function test_RevertIf_UnauthorizedTransfer() public {
        nft.mint(alice, 2);

        vm.prank(bob);
        vm.expectRevert(ERC721A.NotOwnerOrApproved.selector);
        nft.transferFrom(alice, bob, 0);
    }
}
