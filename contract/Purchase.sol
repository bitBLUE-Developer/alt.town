// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Purchase is Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    struct Order {
        address buyer;
        uint256 amount;
        uint256 nonce;
        bytes32 verify;
    }
    address public recipient;

    mapping(address => uint256) public nonces;
    mapping(bytes32 => bool) public executedOrders;
    mapping(address => mapping(uint256 => Order)) public excutedBuyerOrders;
    mapping(bytes32 => Order)  public ordersByVerify;


    event PurchaseMade(address indexed buyer, uint256 amount, uint256 nonce, uint256 value);

    constructor(address _recipient) Ownable(msg.sender){
        recipient = _recipient;
    }

    // Allow the owner to withdraw the Ether balance
    function withdraw(address to) external onlyOwner {
        (bool success, ) = payable(to).call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    function purchase(Order memory order) public payable nonReentrant{
        require(msg.value == order.amount, "Incorrect BNB value");
        require(msg.sender == order.buyer, "Invalid sender");
        require(order.nonce == nonces[order.buyer], "Invalid nonce");
        require(order.verify!= "", "Invalid verify");
        require(!executedOrders[order.verify], "Order already executed");
        nonces[order.buyer]++;
        excutedBuyerOrders[order.buyer][order.nonce] = Order({
            buyer: order.buyer,
            amount: order.amount,
            nonce: order.nonce,
            verify: order.verify
        });
        ordersByVerify[order.verify] = Order({
            buyer: order.buyer,
            amount: order.amount,
            nonce: order.nonce,
            verify: order.verify
        });
        executedOrders[order.verify] = true;
        (bool success, ) = payable(recipient).call{value: order.amount}("");
        require(success, "Transfer failed");
        emit PurchaseMade(order.buyer, order.amount, order.nonce, msg.value);
    }

    function setRecipient(address _recipient) external onlyOwner {
        recipient = _recipient;
    }
}
