// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Errors} from "./lib/Errors.sol";

/// @title SharesToken
/// @author YovchevYoan
/// @notice Abstract contract representing the shares of the investors, who have invested in an EstateProject
abstract contract SharesToken {
    /// @notice Emmited when a transfer of tokens has been invoked
    /// @param from The address from which the tokens are transfered
    /// @param to The address to which the tokens are trasnfered
    /// @param amount The amount of tokens being transfered
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @notice Emmited when an approval has been invoked
    /// @param owner The address of the owner who allowes the tokens
    /// @param spender The address which is being allowed the tokens
    /// @param amount The amount of tokens being allowed
    event Approve(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /// @notice The name of the share token
    string public s_name;

    /// @notice The symbol of the share token
    string public s_symbol;

    /// @notice The decimals of the share token
    uint256 public constant DECIMALS = 18;

    /// @notice The total supply of share tokens
    uint256 private s_totalSupply;

    /// @notice Onwer => Amount
    mapping(address owner => uint256 amount) s_balances;
    /// @notice Owner => Spender => Amount
    mapping(address owner => mapping(address spender => uint256 amount)) s_allowances;

    /// @param name The name of the share token
    /// @param symbol The symbol of the share token
    constructor(string memory name, string memory symbol) {
        s_name = name;
        s_symbol = symbol;
    }

    /// @notice Mints tokens to the provided address
    /// @param to The address to mint the tokens to
    /// @param amount The amount of tokens to be minted
    function _mint(address to, uint256 amount) internal {
        s_balances[to] += amount;
        s_totalSupply += amount;

        emit Transfer(address(0), to, amount);
    }

    /// @notice Burns tokens to the provided address
    /// @param from The address to burn the tokens from
    /// @param amount The amount of tokens to be burned
    function _burn(address from, uint256 amount) internal {
        uint256 userBalance = s_balances[from];
        if (userBalance < amount) revert Errors.AmountExceeds();
        s_balances[from] -= amount;
        s_totalSupply -= amount;

        emit Transfer(from, address(0), amount);
    }

    /// @notice Approves the spender to spend tokens of the behalf of the msg.msg.sender
    /// @param spender The address being approved of the amount
    /// @param amount The amount of tokens being approves
    function approve(address spender, uint256 amount) external returns (bool) {
        s_allowances[msg.sender][spender] = amount;

        emit Approve(msg.sender, spender, amount);

        return true;
    }

    /// @notice Transfers tokens from the msg.sender to the specified address
    /// @param to The address to transfer the tokens to
    /// @param amount The amount of tokens to transfer
    function transfer(address to, uint256 amount) external returns (bool) {
        if (amount > s_balances[msg.sender]) revert Errors.AmountExceeds();

        s_balances[msg.sender] -= amount;
        s_balances[to] += amount;

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    /// @notice Transferes tokens from the `from` address to the `to` address
    /// @dev Checks if the msg.sender has enough allowance from the `from` address
    /// @param from The address from which the tokens are being deducted
    /// @param to The address from which the tokens are being transfered
    /// @param amount The amount of tokens to be transfered
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        uint256 allowed = s_allowances[from][msg.sender];
        if (amount > allowed) revert Errors.AmountExceeds();
        if (allowed != type(uint256).max)
            s_allowances[from][msg.sender] = allowed - amount;

        s_balances[from] -= amount;
        s_balances[to] += amount;

        emit Transfer(from, to, amount);

        return true;
    }
}
