// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Withdraw is Ownable{
    using ECDSA for bytes32;

    mapping(address => uint256) public nonces;

    event Received(address indexed sender, uint256 amount);
    event Withdrawal(address indexed withdrawAddress, uint256 nonce, uint256 amount);

    constructor() Ownable(msg.sender){
    }

    function withdraw(address payable withdrawAddress, uint256 amount, uint256 nonce) external payable onlyOwner {
        require(nonce == nonces[withdrawAddress], "Invalid nonce");
        (bool success, ) = payable(withdrawAddress).call{value: amount}("");
        require(success, "Withdraw failed");
        emit Withdrawal(withdrawAddress, nonce, amount);
        nonces[withdrawAddress]++;
    }

    // Allow the owner to withdraw the Ether balance
    function ownerWithdraw(address to) external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No BNB available for withdrawal");

        (bool success, ) = payable(to).call{value: balance}("");
        require(success, "Transfer failed");
    }

    // Receive function to accept BNB
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    // Fallback function to handle calls with data
    fallback() external payable {
        emit Received(msg.sender, msg.value);
    }
}
