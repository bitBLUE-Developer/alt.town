// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/base/ERC20Base.sol";

contract DNA is ERC20Base {
    uint256 private constant MAX_SUPPLY = 1000000 ether;
    address public immutable ALT_ADDRESS;
    address public immutable TREASURY_ECO_ADDRESS;
    address public immutable COMMUNITY_ADDRESS;
    address public immutable SALE_ADDRESS;
    address public immutable EVENT_ADDRESS;
    mapping(address => uint256) private LOCKED_BALANCE;

    uint256 private constant ALT_UNLOCK_BALANCE = 10000 ether;
    uint8 private constant ALT_UNLOCK_MAX_COUNT = 30;
    uint256 private constant ALT_BALANCE = ALT_UNLOCK_MAX_COUNT * ALT_UNLOCK_BALANCE;

    uint256 private constant TREASURE_ECO_BALANCE = 400000 ether;
    uint256[] private TREASURE_ECO_UNLOCK_BALANCE = [10000 ether, 50000 ether, 50000 ether, 50000 ether, 100000 ether, 140000 ether];

    uint256 private constant COMMUNITY_BALANCE = 200000 ether;
    uint256 private constant COMMUNITY_UNLOCK_BALANCE = 20000 ether;
    uint8 private constant COMMUNITY_UNLOCK_MAX_COUNT = 10;

    uint256 private constant SALE_BALANCE = 100000 ether;
    uint256 public immutable PRESALE_START_DATE;
    uint256 public immutable PRESALE_END_DATE;
    uint256 private NOT_SOLD_BALANCE = 0 ether;
    uint8 private constant NOT_SOLD_BALANCE_MAX_COUNT = 40;
    mapping(address => bool) public marketAddressWhitelist;
    bool public PRESALE_UNLOCK = false;


    constructor(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address _altAddress,
        address _treasuryEcoAddress,
        address _communityAddress,
        address _saleAddress,
        address _eventAddress,
        uint256 _presaleStartDate,
        uint256 _presaleEndDate
    ) ERC20Base(msg.sender, _name, _symbol){
        ALT_ADDRESS = _altAddress;
        TREASURY_ECO_ADDRESS = _treasuryEcoAddress;
        COMMUNITY_ADDRESS = _communityAddress;
        SALE_ADDRESS = _saleAddress;
        EVENT_ADDRESS = _eventAddress;
        PRESALE_START_DATE = _presaleStartDate;
        PRESALE_END_DATE = _presaleEndDate;
        mintTo(ALT_ADDRESS, ALT_BALANCE);
        mintTo(TREASURY_ECO_ADDRESS, TREASURE_ECO_BALANCE);
        mintTo(COMMUNITY_ADDRESS, COMMUNITY_BALANCE);
        mintTo(SALE_ADDRESS, SALE_BALANCE);
        _setupContractURI(_contractURI);
        addAddressToWhitelist(msg.sender);
        addAddressToWhitelist(_defaultAdmin);
    }

    function altLockBalance() public view returns (uint256){
        if(block.timestamp >= PRESALE_START_DATE + 4320 hours){
            uint256 _length = (block.timestamp - (PRESALE_START_DATE + 4320 hours)) / 720 hours + 1;
            uint256 _count = _length > ALT_UNLOCK_MAX_COUNT ? ALT_UNLOCK_MAX_COUNT : _length;
            return ALT_BALANCE - _count * ALT_UNLOCK_BALANCE;
        }
        return ALT_BALANCE;
    }

    function treasureEcoLockBalance() public view returns (uint256){
        if(block.timestamp >= PRESALE_START_DATE + 0 hours){
            uint256 _length = TREASURE_ECO_UNLOCK_BALANCE.length;
            uint256 _count = (block.timestamp - (PRESALE_START_DATE + 0 hours)) / 8760 hours + 1;
            _count = _count > _length? _length : _count;
            uint256 _sum = 0;
            for(uint256 i=0;i<_count;i++){
                _sum += TREASURE_ECO_UNLOCK_BALANCE[i];
            }
            return TREASURE_ECO_BALANCE - _sum;
        }

        return TREASURE_ECO_BALANCE;
    }

    function communityLockBalance() public view returns (uint256){
        if(block.timestamp >= PRESALE_START_DATE + 0 hours){
            uint256 _length = (block.timestamp - (PRESALE_START_DATE + 0 hours)) / 4320 hours + 1;
            uint256 _count = _length > COMMUNITY_UNLOCK_MAX_COUNT ? COMMUNITY_UNLOCK_MAX_COUNT : _length;
            return COMMUNITY_BALANCE - _count * COMMUNITY_UNLOCK_BALANCE;
        }
        return COMMUNITY_BALANCE;
    }

    function notSoldLockBalance() public view returns (uint256){
        if(block.timestamp >= PRESALE_END_DATE + 8760 hours){
            uint256 _length = (block.timestamp - (PRESALE_END_DATE + 8760 hours)) / 720 hours + 1;
            uint256 _count = _length > COMMUNITY_UNLOCK_MAX_COUNT ? COMMUNITY_UNLOCK_MAX_COUNT : _length;
            uint256 _amount = NOT_SOLD_BALANCE / 1 ether / NOT_SOLD_BALANCE_MAX_COUNT;
            return NOT_SOLD_BALANCE_MAX_COUNT >= _count ? 0 : NOT_SOLD_BALANCE - _amount * _count * 1 ether;
        }
        return NOT_SOLD_BALANCE;
    }

    function setNotSoldLockBalance(uint256 _balance) public returns (uint256){
        require(isWhitelisted(_msgSender()), "Not Whitelisted");
        require(!PRESALE_UNLOCK, "Presale Already Unlocked");
        require(block.timestamp>PRESALE_END_DATE, "Presale Not Ended");
        require(balanceOf(SALE_ADDRESS) >= _balance, "Not enough balance");
        require(_balance >= 0, "Not enough balance");
        if(_balance < 80){
            _transfer(SALE_ADDRESS, EVENT_ADDRESS, _balance);
            NOT_SOLD_BALANCE = 0;
        }else{
            NOT_SOLD_BALANCE = _balance;
        }
        PRESALE_UNLOCK = true;
        return NOT_SOLD_BALANCE;
    }

    function lockedTotalBalance(address _address) public view returns (uint256){
        uint256 _lockedAltBalance = ALT_ADDRESS == _address ? altLockBalance() : 0;
        uint256 _lockedTreasureEcoBalance = TREASURY_ECO_ADDRESS == _address ? treasureEcoLockBalance() : 0;
        uint256 _lockedCommunityBalance = COMMUNITY_ADDRESS == _address ? communityLockBalance() : 0;
        uint256 _lockedNotSoldBalance = SALE_ADDRESS == _address ? notSoldLockBalance() : 0;
        uint256 _lockedTotalBalance = _lockedAltBalance + _lockedTreasureEcoBalance + _lockedCommunityBalance + _lockedNotSoldBalance;
        return _lockedTotalBalance;
    }

    function transfer(address to, uint256 amount) public virtual override onlyOwner returns (bool) {
        return super.transfer(to, amount);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public virtual override returns (bool){
        require(_amount>0, "Transfer amount must be greater than zero");
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(_amount <= balanceOf(_from) - lockedTotalBalance(_from), "ERC20: transfer amount exceeds balance");
        require(owner() == _msgSender() || isWhitelisted(_msgSender()), "ERC20: transfer from incorrect owner");
        _transfer(_from, _to, _amount);
        return true;
//        if(owner() == _msgSender()) {
//            _transfer(_from, _to, _amount);
//            return true;
//        }else{
//            return super.transferFrom(_from, _to, _amount);
//        }
    }

    function mintTo(address _to, uint256 _amount) public virtual override{
        require(totalSupply() + _amount <= MAX_SUPPLY, "Max supply reached");
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

    event MarketListed(address indexed _marketAddress);
    event MarketUnlisted(address indexed _marketAddress);

}