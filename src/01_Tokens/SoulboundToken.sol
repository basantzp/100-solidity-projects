// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title SoulboundToken (EIP-5114)
/// @notice Non-transferable identity badges and soulbound credentials.
/// @dev Any transfer or approval reverts; only minting and burning/revocation are permitted.
contract SoulboundToken {
    // --- Errors ---
    error NonTransferable();
    error NotAuthorized();
    error TokenDoesNotExist();
    error AlreadyMinted();
    error ZeroAddress();

    // --- Events ---
    event Issued(address indexed to, uint256 indexed tokenId, string uri);
    event Revoked(address indexed from, uint256 indexed tokenId);

    // --- State Variables ---
    string public name;
    string public symbol;
    address public immutable issuer;

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => string) private _tokenURIs;

    modifier onlyIssuer() {
        if (msg.sender != issuer) revert NotAuthorized();
        _;
    }

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        issuer = msg.sender;
    }

    /// @notice Issue a non-transferable soulbound token to a recipient
    function issue(address to, uint256 tokenId, string calldata uri) external onlyIssuer {
        if (to == address(0)) revert ZeroAddress();
        if (_owners[tokenId] != address(0)) revert AlreadyMinted();

        _owners[tokenId] = to;
        _balances[to] += 1;
        _tokenURIs[tokenId] = uri;

        emit Issued(to, tokenId, uri);
    }

    /// @notice Revoke / burn a soulbound token. Can be triggered by the issuer or token soul
    function revoke(uint256 tokenId) external {
        address tokenOwner = _owners[tokenId];
        if (tokenOwner == address(0)) revert TokenDoesNotExist();
        if (msg.sender != issuer && msg.sender != tokenOwner) revert NotAuthorized();

        delete _owners[tokenId];
        delete _tokenURIs[tokenId];
        _balances[tokenOwner] -= 1;

        emit Revoked(tokenOwner, tokenId);
    }

    /// @notice Lookup owner of a token ID
    function ownerOf(uint256 tokenId) external view returns (address) {
        address tokenOwner = _owners[tokenId];
        if (tokenOwner == address(0)) revert TokenDoesNotExist();
        return tokenOwner;
    }

    /// @notice Lookup token URI
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        if (_owners[tokenId] == address(0)) revert TokenDoesNotExist();
        return _tokenURIs[tokenId];
    }

    /// @notice Soulbound tokens cannot be transferred
    function transferFrom(address, address, uint256) external pure {
        revert NonTransferable();
    }

    /// @notice Soulbound tokens cannot be safe transferred
    function safeTransferFrom(address, address, uint256) external pure {
        revert NonTransferable();
    }

    /// @notice Approvals are disabled for soulbound tokens
    function approve(address, uint256) external pure {
        revert NonTransferable();
    }

    /// @notice Operator approvals are disabled for soulbound tokens
    function setApprovalForAll(address, bool) external pure {
        revert NonTransferable();
    }

    function balanceOf(address account) external view returns (uint256) {
        if (account == address(0)) revert ZeroAddress();
        return _balances[account];
    }
}
