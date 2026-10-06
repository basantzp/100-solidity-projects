// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title ERC721A
/// @notice Gas-optimized batch minting NFT contract inspired by the Azuki ERC721A standard.
/// @dev Slashes batch minting gas from O(N) to O(1) by lazily initializing ownership slots.
contract ERC721A {
    // --- Errors ---
    error MintZeroQuantity();
    error NonExistentToken();
    error NotOwnerOrApproved();
    error TransferToZeroAddress();
    error ApprovalToCurrentOwner();
    error TransferFromIncorrectOwner();

    // --- Events ---
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // --- Structs ---
    struct TokenOwnership {
        address addr;
        uint64 startTimestamp;
        bool burned;
    }

    struct AddressData {
        uint64 balance;
        uint64 numberMinted;
    }

    // --- State Variables ---
    string public name;
    string public symbol;
    uint256 public currentIndex;

    mapping(uint256 => TokenOwnership) internal _ownerships;
    mapping(address => AddressData) internal _addressData;
    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function totalSupply() external view returns (uint256) {
        return currentIndex;
    }

    function balanceOf(address owner) external view returns (uint256) {
        if (owner == address(0)) revert TransferToZeroAddress();
        return _addressData[owner].balance;
    }

    /// @notice Batch mint quantity tokens to recipient with O(1) SSTOREs
    function mint(address to, uint256 quantity) external {
        if (to == address(0)) revert TransferToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        uint256 startTokenId = currentIndex;

        _addressData[to].balance += uint64(quantity);
        _addressData[to].numberMinted += uint64(quantity);

        _ownerships[startTokenId] = TokenOwnership({addr: to, startTimestamp: uint64(block.timestamp), burned: false});

        unchecked {
            for (uint256 i = 0; i < quantity; ++i) {
                emit Transfer(address(0), to, startTokenId + i);
            }
            currentIndex += quantity;
        }
    }

    /// @notice Find the owner of tokenId by scanning backwards to the nearest initialized slot
    function ownerOf(uint256 tokenId) public view returns (address) {
        return _ownershipOf(tokenId).addr;
    }

    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        if (tokenId >= currentIndex) revert NonExistentToken();

        for (uint256 curr = tokenId + 1; curr > 0; --curr) {
            TokenOwnership memory ownership = _ownerships[curr - 1];
            if (ownership.burned) revert NonExistentToken();
            if (ownership.addr != address(0)) {
                return ownership;
            }
        }
        revert NonExistentToken();
    }

    function approve(address to, uint256 tokenId) external {
        address owner = ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();
        if (msg.sender != owner && !isApprovedForAll[owner][msg.sender]) {
            revert NotOwnerOrApproved();
        }

        getApproved[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);
        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();
        if (to == address(0)) revert TransferToZeroAddress();

        bool isApprovedOrOwner =
            (msg.sender == from || isApprovedForAll[from][msg.sender] || getApproved[tokenId] == msg.sender);
        if (!isApprovedOrOwner) revert NotOwnerOrApproved();

        delete getApproved[tokenId];

        _addressData[from].balance -= 1;
        _addressData[to].balance += 1;

        _ownerships[tokenId] = TokenOwnership({addr: to, startTimestamp: uint64(block.timestamp), burned: false});

        // Maintain ownership continuation for the next sequential token if not yet initialized
        unchecked {
            uint256 nextTokenId = tokenId + 1;
            if (nextTokenId < currentIndex && _ownerships[nextTokenId].addr == address(0)) {
                _ownerships[nextTokenId] = TokenOwnership({
                    addr: prevOwnership.addr, startTimestamp: prevOwnership.startTimestamp, burned: false
                });
            }
        }

        emit Transfer(from, to, tokenId);
    }
}
