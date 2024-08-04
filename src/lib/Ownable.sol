// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Errors} from "./Errors.sol";

/// @title Ownable
/// @author YovchevYoan
/// @notice Abstract contract including functionality for ownership
abstract contract Ownable {
    /// @notice The address of the current owner
    address private s_owner;

    /// @notice Emmited when the ownership has been transfered
    /// @param oldOwner The address of the old owner
    /// @param newOwner The address of the new owner
    event OwnershipTransfer(address oldOwner, address newOwner);

    /// @param initialOwner The address of the initial owner
    constructor(address initialOwner) {
        if (initialOwner == address(0)) revert Errors.AddressZero();
        _transferOwnership(initialOwner);
    }

    /// @notice Modifier ensures only the current owner can call the function
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /// @notice Returns the current owner
    function owner() public view virtual returns (address) {
        return s_owner;
    }

    /// @notice Returns the msg.sender
    function msgSender() public view returns (address) {
        return msg.sender;
    }

    /// @notice Checks to see if the msg.sender is the current owner
    function _checkOwner() internal view virtual {
        if (msgSender() != owner()) revert Errors.NotOwner();
    }

    /// @notice Transferes the ownership to address(0), thus renouncing it
    /// @dev Only callable by the current owner
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /// @notice Transfers the ownership to a new owner
    /// @dev Only callable by the current owner
    /// @param newOwner The address of the new owner
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) revert Errors.AddressZero();
        _transferOwnership(newOwner);
    }

    /// @notice Internal function containing the logic for transfering the ownership
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = s_owner;
        s_owner = newOwner;
        emit OwnershipTransfer(oldOwner, newOwner);
    }
}
