// contracts/TownToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TownToken is ERC20, ERC20Burnable, Ownable {
    constructor(address initialOwner, string memory name_, string memory symbol_) ERC20(name_, symbol_) Ownable(initialOwner)
    {
        _mint(initialOwner, 2_000_000_000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
