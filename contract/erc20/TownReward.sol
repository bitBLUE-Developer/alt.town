// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract TownReward {
    using BitMaps for BitMaps.BitMap;
    using SafeERC20 for IERC20;

    address public immutable token;
    bytes32 public immutable merkleRoot;
    uint256 public totalClaimedAmount;
    uint256 public start;
    uint256 public end;

    address public owner;

    mapping(uint256 => uint256) public claimed;
    BitMaps.BitMap private _revokedBitmap;

    error InvalidProof();
    error NothingToClaim();
    error EmptyMerkleRoot();
    error OnlyOwner();
    error AlreadyRevoked();
    error ZeroAddress();
    error ClaimAmountGtClaimable();
    error Revoked();

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Claim(address indexed account, uint256 amount);
    event RewardRevoked(address indexed account, uint256 amountUnrewarded);

    constructor(
        address _token,
        uint256 _start,
        uint256 _end,
        bytes32 _merkleRoot,
        address _owner
    ) {
        if (_merkleRoot == "") revert EmptyMerkleRoot();

        token = _token;
        merkleRoot = _merkleRoot;

        owner = _owner;
        start = _start;
        end = _end;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof,
        uint256 claimAmount
    ) public {
        bytes32 node = keccak256(
            abi.encodePacked(index, account, amount)
        );
        if (!MerkleProof.verify(merkleProof, merkleRoot, node)) revert InvalidProof();

        if (getRevoked(index)) revert Revoked();

        uint256 claimable = getClaimable(index, amount);

        if (claimable == 0) revert NothingToClaim();
        if (claimAmount > claimable) revert ClaimAmountGtClaimable();

        totalClaimedAmount += claimAmount;
        claimed[index] += claimAmount;

        IERC20(token).safeTransfer(account, claimAmount);

        emit Claim(account, claimAmount);
    }

    function stopReward(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external onlyOwner {
        bytes32 node = keccak256(
            abi.encodePacked(index, account, amount)
        );
        if (!MerkleProof.verify(merkleProof, merkleRoot, node)) revert InvalidProof();

        if (getRevoked(index)) revert AlreadyRevoked();

        uint256 alreadyClaimed = claimed[index];
        uint256 claimable = getClaimable(index, amount);

        setRevoked(index);

        uint256 rest = amount - (alreadyClaimed + claimable);
        if(rest != 0) {
            IERC20(token).safeTransfer(owner, rest);
            emit RewardRevoked(account, rest);
        }
    }

    function getClaimable(
        uint256 index,
        uint256 amount
    ) public view returns (uint256) {
        if (block.timestamp < start || block.timestamp > end) return 0;
        return amount - claimed[index];
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function getRevoked(uint256 index) public view returns (bool) {
        return _revokedBitmap.get(index);
    }

    function setRevoked(uint256 index) internal {
        _revokedBitmap.set(index);
    }
}