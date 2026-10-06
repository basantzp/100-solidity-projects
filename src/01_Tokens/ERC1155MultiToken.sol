// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title ERC1155MultiToken
/// @notice Gas-optimized implementation of the ERC-1155 Multi-Token Standard
contract ERC1155MultiToken {
    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(
        address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values
    );
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);

    /* -------------------------------------------------------------------------- */
    /*                                   ERRORS                                   */
    /* -------------------------------------------------------------------------- */
    error NotOwnerOrApproved();
    error InsufficientBalance(address account, uint256 id, uint256 balance, uint256 required);
    error ArrayLengthMismatch();
    error InvalidRecipient(address recipient);
    error UnsafeRecipient(address recipient);

    /* -------------------------------------------------------------------------- */
    /*                                    STATE                                   */
    /* -------------------------------------------------------------------------- */
    string public uri;
    mapping(uint256 => mapping(address => uint256)) public balanceOf;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    constructor(string memory _uri) {
        uri = _uri;
    }

    function setApprovalForAll(address operator, bool approved) external {
        if (operator == address(0)) revert InvalidRecipient(address(0));
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory batchBalances)
    {
        if (accounts.length != ids.length) revert ArrayLengthMismatch();
        batchBalances = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            batchBalances[i] = balanceOf[ids[i]][accounts[i]];
        }
    }

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) public {
        if (to == address(0)) revert InvalidRecipient(address(0));
        if (from != msg.sender && !isApprovedForAll[from][msg.sender]) revert NotOwnerOrApproved();

        uint256 fromBalance = balanceOf[id][from];
        if (fromBalance < amount) revert InsufficientBalance(from, id, fromBalance, amount);

        unchecked {
            balanceOf[id][from] = fromBalance - amount;
            balanceOf[id][to] += amount;
        }

        emit TransferSingle(msg.sender, from, to, id, amount);

        if (to.code.length > 0) {
            _checkOnERC1155Received(from, to, id, amount, data);
        }
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes memory data
    ) public {
        if (to == address(0)) revert InvalidRecipient(address(0));
        if (ids.length != amounts.length) revert ArrayLengthMismatch();
        if (from != msg.sender && !isApprovedForAll[from][msg.sender]) revert NotOwnerOrApproved();

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            uint256 fromBalance = balanceOf[id][from];
            if (fromBalance < amount) revert InsufficientBalance(from, id, fromBalance, amount);

            unchecked {
                balanceOf[id][from] = fromBalance - amount;
                balanceOf[id][to] += amount;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        if (to.code.length > 0) {
            _checkOnERC1155BatchReceived(from, to, ids, amounts, data);
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                                MINT / BURN                                 */
    /* -------------------------------------------------------------------------- */

    function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal {
        if (to == address(0)) revert InvalidRecipient(address(0));

        unchecked {
            balanceOf[id][to] += amount;
        }

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        if (to.code.length > 0) {
            _checkOnERC1155Received(address(0), to, id, amount, data);
        }
    }

    function _burn(address from, uint256 id, uint256 amount) internal {
        uint256 fromBalance = balanceOf[id][from];
        if (fromBalance < amount) revert InsufficientBalance(from, id, fromBalance, amount);

        unchecked {
            balanceOf[id][from] = fromBalance - amount;
        }

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }

    /* -------------------------------------------------------------------------- */
    /*                              RECEIVER CHECKS                               */
    /* -------------------------------------------------------------------------- */

    function _checkOnERC1155Received(address from, address to, uint256 id, uint256 amount, bytes memory data) private {
        // onERC1155Received selector: 0xf23a6e61
        (bool success, bytes memory returnData) =
            to.call(abi.encodeWithSelector(0xf23a6e61, msg.sender, from, id, amount, data));
        if (!success || returnData.length < 4 || abi.decode(returnData, (bytes4)) != bytes4(0xf23a6e61)) {
            revert UnsafeRecipient(to);
        }
    }

    function _checkOnERC1155BatchReceived(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes memory data
    ) private {
        // onERC1155BatchReceived selector: 0xbc19780f
        (bool success, bytes memory returnData) =
            to.call(abi.encodeWithSelector(0xbc19780f, msg.sender, from, ids, amounts, data));
        if (!success || returnData.length < 4 || abi.decode(returnData, (bytes4)) != bytes4(0xbc19780f)) {
            revert UnsafeRecipient(to);
        }
    }

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return
            interfaceId == 0x01ffc9a7 // ERC-165
                || interfaceId == 0xd9b67a26 // ERC-1155
                || interfaceId == 0x0e89341c; // ERC-1155Metadata_URI
    }
}
