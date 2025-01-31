// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/base/ERC20Base.sol";

contract KEY is ERC20Base {
    constructor(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol
    ) ERC20Base(msg.sender, _name, _symbol){
        addAddressToWhitelist(msg.sender);
        addAddressToWhitelist(_defaultAdmin);
    }

    mapping(address => bool) public marketAddressWhitelist;

    function transfer(address _to, uint256 _amount) public virtual override returns (bool) {
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(owner() == _msgSender() || isWhitelisted(_msgSender()), "ERC20: transfer from incorrect owner");
        _transfer(_msgSender(), _to, _amount);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public virtual override returns (bool){
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(owner() == _msgSender() || isWhitelisted(_msgSender()), "ERC20: transfer from incorrect owner");
        _transfer(_from, _to, _amount);
        return true;
    }

    function burnFrom(
        address _account, uint256 _amount
    )public virtual override{
        require(owner() == _msgSender() || isWhitelisted(_msgSender()), "ERC20: transfer from incorrect owner");
        require(balanceOf(_account) >= _amount, "not enough balance");
        _burn(_account, _amount);
    }

    function mintTo(address _to, uint256 _amount) public virtual override{
        super.mintTo(_to, _amount);
    }

    function addAddressToWhitelist(address _address) public onlyOwner {
        marketAddressWhitelist[_address] = true;
        emit MarketListed(_address);
    }

    function removeAddressFromWhitelist(address _address) public onlyOwner {
        marketAddressWhitelist[_address] = false;
        emit MarketUnlisted(_address);
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return marketAddressWhitelist[_address];
    }

    function _canMint() internal view virtual override returns (bool) {
        return msg.sender == owner() || isWhitelisted(_msgSender());
    }

    event MarketListed(address indexed _marketAddress);
    event MarketUnlisted(address indexed _marketAddress);
}