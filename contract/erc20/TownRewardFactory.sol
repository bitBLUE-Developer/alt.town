// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./TownReward.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract TownRewardFactory is Ownable, ReentrancyGuard {
    constructor() Ownable(msg.sender){}

    using SafeERC20 for IERC20;

    error NotContract();
    error ZeroAddress();
    error ZeroAmount();
    error EthTransferFailed();

    event RewardCreated(
        address indexed creator,
        address rewardAddr,
        address indexed token,
        bytes32 merkleRoot,
        uint256 totalAmount
    );

    function createReward(
        address token,
        uint256 start,
        uint256 end,
        bytes32 merkleRoot,
        uint256 totalAmount
    ) external payable nonReentrant {
        if (totalAmount == 0) revert ZeroAmount();

        TownReward reward = new TownReward(token, start, end,  merkleRoot, msg.sender);

        IERC20(token).transfer(address(reward), totalAmount);

        emit RewardCreated(msg.sender, address(reward), token, merkleRoot, totalAmount);
    }
}