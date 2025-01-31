// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/external-deps/openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "@thirdweb-dev/contracts/extension/Ownable.sol";

contract Swapper is Ownable{
    IERC20 private tokenKey;
    constructor(address _defaultAdmin, address _key){
        _setupOwner(_defaultAdmin);
        tokenKey = IERC20(_key);
    }

    function swap(address dnaContract, address to, address from, address systemWalletAddress, address altWalletAddress, uint256 dnaAmount, uint256 keyAmount, uint256 buyFee, uint256 sellFee, uint256 systemFee, uint256 altFee) external onlyOwner{
        require(buyFee + sellFee == systemFee + altFee, "buyFee + sellFee != systemFee + altFee");
        require(IERC20(dnaContract).transferFrom(to, from, dnaAmount), "ERC20: Error on transfer");
        require(tokenKey.transferFrom(from, to, keyAmount), "Error");
        if(sellFee > 0) require(tokenKey.transferFrom(to, address(this), sellFee), "sellFee Error");
        if(buyFee > 0) require(tokenKey.transferFrom(from, address(this), buyFee), "buyFee Error");
        if(systemFee > 0) require(tokenKey.transfer(systemWalletAddress, systemFee), "systemFee Error");
        if(altFee > 0) require(tokenKey.transfer(altWalletAddress, altFee), "altFee Error");
    }

    function preSale(address dnaContract, address to, address presaleWalletAddress, address systemWalletAddress, address altWalletAddress, uint256 dnaAmount, uint256 keyAmount, uint256 systemAmount, uint256 altAmount) external onlyOwner{
        require(keyAmount == systemAmount + altAmount, "keyAmount != systemAmount + altAmount");
        require(tokenKey.transferFrom(to, address(this), keyAmount), "key Transfer Error");
        require(IERC20(dnaContract).transferFrom(presaleWalletAddress, to, dnaAmount), "ERC20: Error on transfer DNA");
        if(altAmount > 0) require(tokenKey.transfer(altWalletAddress, altAmount), "altAmount Error");
        if(systemAmount > 0) require(tokenKey.transfer(systemWalletAddress, systemAmount), "systemAmount Error");
    }

    function _canSetOwner() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }
}