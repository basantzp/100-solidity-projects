// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title ERC721NFT
/// @notice Production-grade, gas-optimized ERC-721 implementation with EIP-2981 royalty support
contract ERC721NFT {
    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /* -------------------------------------------------------------------------- */
    /*                                   ERRORS                                   */
    /* -------------------------------------------------------------------------- */
    error NotOwnerOrApproved();
    error NonexistentToken(uint256 tokenId);
    error TokenAlreadyMinted(uint256 tokenId);
    error InvalidRecipient(address recipient);
    error UnsafeRecipient(address recipient);
    error InvalidRoyaltyPercentage(uint96 feeNumerator);

    /* -------------------------------------------------------------------------- */
    /*                                    STATE                                   */
    /* -------------------------------------------------------------------------- */
    string public name;
    string public symbol;

    mapping(uint256 => address) public ownerOf;
    mapping(address => uint256) public balanceOf;
    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    // EIP-2981 Royalty configuration
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }
    RoyaltyInfo public defaultRoyalty;
    uint256 public constant ROYALTY_FEE_DENOMINATOR = 10000;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /* -------------------------------------------------------------------------- */
    /*                                ERC721 LOGIC                                */
    /* -------------------------------------------------------------------------- */

    function approve(address spender, uint256 tokenId) external {
        address owner = ownerOf[tokenId];
        if (owner == address(0)) revert NonexistentToken(tokenId);
        if (msg.sender != owner && !isApprovedForAll[owner][msg.sender]) {
            revert NotOwnerOrApproved();
        }

        getApproved[tokenId] = spender;
        emit Approval(owner, spender, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        if (to == address(0)) revert InvalidRecipient(address(0));
        address owner = ownerOf[tokenId];
        if (owner == address(0)) revert NonexistentToken(tokenId);
        if (from != owner) revert NotOwnerOrApproved();

        if (msg.sender != owner && msg.sender != getApproved[tokenId] && !isApprovedForAll[owner][msg.sender]) {
            revert NotOwnerOrApproved();
        }

        delete getApproved[tokenId];
        unchecked {
            balanceOf[from]--;
            balanceOf[to]++;
        }
        ownerOf[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        transferFrom(from, to, tokenId);
        if (to.code.length > 0) {
            try this.checkOnERC721Received(msg.sender, from, to, tokenId, data) returns (bool success) {
                if (!success) revert UnsafeRecipient(to);
            } catch {
                revert UnsafeRecipient(to);
            }
        }
    }

    function checkOnERC721Received(address operator, address from, address to, uint256 tokenId, bytes memory data)
        external
        returns (bool)
    {
        // Selector of onERC721Received(address,address,uint256,bytes): 0x150b7a02
        (bool success, bytes memory returnData) =
            to.call(abi.encodeWithSelector(0x150b7a02, operator, from, tokenId, data));
        return success && returnData.length >= 4 && abi.decode(returnData, (bytes4)) == bytes4(0x150b7a02);
    }

    /* -------------------------------------------------------------------------- */
    /*                                MINT / BURN                                 */
    /* -------------------------------------------------------------------------- */

    function _mint(address to, uint256 tokenId) internal {
        if (to == address(0)) revert InvalidRecipient(address(0));
        if (ownerOf[tokenId] != address(0)) revert TokenAlreadyMinted(tokenId);

        unchecked {
            balanceOf[to]++;
        }
        ownerOf[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal {
        address owner = ownerOf[tokenId];
        if (owner == address(0)) revert NonexistentToken(tokenId);

        delete getApproved[tokenId];
        unchecked {
            balanceOf[owner]--;
        }
        delete ownerOf[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /* -------------------------------------------------------------------------- */
    /*                             EIP-2981 ROYALTIES                             */
    /* -------------------------------------------------------------------------- */

    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal {
        if (feeNumerator > ROYALTY_FEE_DENOMINATOR) revert InvalidRoyaltyPercentage(feeNumerator);
        defaultRoyalty = RoyaltyInfo({receiver: receiver, royaltyFraction: feeNumerator});
    }

    function royaltyInfo(uint256, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        RoyaltyInfo memory royalty = defaultRoyalty;
        receiver = royalty.receiver;
        royaltyAmount = (salePrice * royalty.royaltyFraction) / ROYALTY_FEE_DENOMINATOR;
    }

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return interfaceId == 0x01ffc9a7 // ERC-165
            || interfaceId == 0x80ac58cd // ERC-721
            || interfaceId == 0x5b5e139f // ERC-721Metadata
            || interfaceId == 0x2a5520c9; // ERC-2981
    }
}
