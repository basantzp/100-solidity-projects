// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Ownable2Step
/// @notice Safe two-step ownership transfer preventing irreversible lockups from mistyped addresses
abstract contract Ownable2Step {
    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    error NotOwner();
    error NotPendingOwner();
    error ZeroAddressOwner();

    address private _owner;
    address private _pendingOwner;

    modifier onlyOwner() {
        if (msg.sender != _owner) revert NotOwner();
        _;
    }

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) revert ZeroAddressOwner();
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(_owner, newOwner);
    }

    function acceptOwnership() public virtual {
        if (msg.sender != _pendingOwner) revert NotPendingOwner();
        delete _pendingOwner;
        address oldOwner = _owner;
        _owner = msg.sender;
        emit OwnershipTransferred(oldOwner, msg.sender);
    }

    function renounceOwnership() public virtual onlyOwner {
        delete _pendingOwner;
        address oldOwner = _owner;
        delete _owner;
        emit OwnershipTransferred(oldOwner, address(0));
    }
}
