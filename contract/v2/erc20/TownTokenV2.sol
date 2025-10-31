// contracts/TownTokenV2.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract TownTokenV2 is ERC20, ERC20Burnable, ERC20Permit, Ownable {
    uint256 public constant MAX_SUPPLY = 2_000_000_000 * 10 ** 18;

    constructor(address initialOwner, string memory name_, string memory symbol_)
    ERC20(name_, symbol_)
    ERC20Permit(name_)
    Ownable(initialOwner)
    {
        _mint(initialOwner, MAX_SUPPLY);
    }

    /**
     * @dev Allows the contract owner to recover any arbitrary ERC-20 tokens
     * that were mistakenly or deliberately sent to this contract address.
     * Protects against tokens getting permanently stuck in the contract.
     * @param tokenAddress The address of the ERC-20 token to withdraw.
     * @param to The destination address to receive the withdrawn tokens.
     * @param amount The amount of tokens to withdraw (including decimals).
     */
    function withdrawERC20(
        address tokenAddress,
        address to,
        uint256 amount
    ) public onlyOwner {
        // Instantiate the external ERC20 token contract interface
        IERC20 token = IERC20(tokenAddress);

        // Call the transfer function of the external token contract
        // to send tokens from *this* contract's balance to the 'to' address.
        require(
            token.transfer(to, amount),
            "ERC20: Transfer failed"
        );
    }}
