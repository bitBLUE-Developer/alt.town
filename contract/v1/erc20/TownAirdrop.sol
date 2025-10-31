// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract TownAirdrop is EIP712, Ownable{
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    string private constant SIGNING_DOMAIN = "TownAirdrop";
    string private constant SIGNATURE_VERSION = "1";

    bytes32 private constant TYPEHASH_AIRDROP = keccak256(abi.encodePacked("Airdrop(address account,uint256 round,uint256 amount,uint256 timestamp)"));

    struct Airdrop {
        address account;
        uint256 round;
        uint256 amount;
        uint256 timestamp;
        bool airdropped;
    }

    struct Round {
        uint256 amount;
        uint256 start;
        uint256 end;
        uint256 airdroppedCount;
        uint256 airdroppedAmount;
    }

    event RoundCreated(
        address indexed creator,
        uint256 start,
        uint256 end,
        uint256 amount
    );

    mapping(address => Airdrop) public airdropList;
    mapping(uint256 => Round) public roundList;

    uint256 public maxRound;

    address public immutable token;
    address public immutable signer;

    constructor(address _initialOwner, address _token, address _signer, Round[] memory _rounds)
    EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION)
    Ownable(_initialOwner)
    {
        require(_rounds.length > 0, "Invalid rounds");
        token = _token;
        signer = _signer;

        maxRound = _rounds.length;
        for (uint256 i = 1; i <= _rounds.length; i++) {
            roundList[i] = _rounds[i-1];
            emit RoundCreated(_initialOwner, _rounds[i-1].start, _rounds[i-1].end, _rounds[i-1].amount);
        }
    }

    function airdrop(uint256 _round, uint256 _amount, uint256 _timestamp, bytes calldata signature) external {
        require(!airdropList[msg.sender].airdropped, "Already claimed");
        require(maxRound >= _round, "Invalid round");
        require(block.timestamp <= roundList[_round].end, "Round is over");
        require(block.timestamp >= roundList[_round].start, "Round is not started");
        require(roundList[_round].airdroppedAmount + _amount <= roundList[_round].amount, "Round is full");

        bytes32 structHash = keccak256(abi.encode(
            TYPEHASH_AIRDROP,
            msg.sender,
            _round,
            _amount,
            _timestamp
        ));

        bytes32 digest = _hashTypedDataV4(structHash);
        address recover = ECDSA.recover(digest, signature);

        require(recover == signer, "Invalid signature");

        airdropList[msg.sender] = Airdrop({
            account: msg.sender,
            round: _round,
            amount: _amount,
            timestamp: _timestamp,
            airdropped: true
        });

        roundList[_round].airdroppedCount += 1;
        roundList[_round].airdroppedAmount += _amount;

        IERC20(token).safeTransfer(msg.sender, _amount);
    }

    function withdraw(uint256 amount) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance >= amount, "Not enough balance");
        IERC20(token).safeTransfer(owner(), amount);
    }
}
