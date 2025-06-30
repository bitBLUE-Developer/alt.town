// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./TownVesting.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract TownVestingFactory is Ownable, ReentrancyGuard {
    constructor() Ownable(msg.sender){}

    using SafeERC20 for IERC20;

    bool public isWethFirst;
    address public usdTokenAddress;
    address public companyWallet;

    error NotContract();
    error ZeroAddress();
    error ZeroAmount();
    error EthTransferFailed();

    event VestingCreated(
        address indexed creator,
        address vestingAddr,
        address indexed token,
        bytes32 merkleRoot,
        uint256 totalAmount
    );

    modifier onlyContract(address account) {
        if (account.code.length == 0) revert NotContract();
        _;
    }

    function createVesting(
        address token,
        uint256[] memory unlockTimestamps,
        uint256[] memory _unlockAmounts,
        bytes32 merkleRoot,
        uint256 totalAmount
    ) external payable nonReentrant {
        if (totalAmount == 0) revert ZeroAmount();

        TownVesting vesting = new TownVesting(token, unlockTimestamps, _unlockAmounts,  merkleRoot, msg.sender);

        IERC20(token).safeTransferFrom(msg.sender, address(vesting), totalAmount);

        emit VestingCreated(msg.sender, address(vesting), token, merkleRoot, totalAmount);
    }
}