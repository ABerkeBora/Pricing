// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Safekeep {
    IERC20 public token;
    IERC20 public vestingContract;
    uint256 public lockedAmount;
    address[] public keyHolders;
    mapping(address => bool) public isKeyHolder;
    mapping(address => mapping(address => uint256)) public approval;
    uint256 public createTime;
    mapping(uint8 => bool) public isTermUnlocked;
    mapping(uint8 => uint256) public unlockAmount;
    event TermUnlocked(uint8 term, uint256 unlockedTokenWithTerm);

    modifier onlyKeyHolder() {
        require(isKeyHolder[msg.sender], "Not a Key Holder!");
        _;
    }

    constructor(address[] memory _keyHolders, ERC20 _token) {
        require(
            _keyHolders.length == 3,
            "There should be 3 adresses as keyHolders"
        );
        for (uint256 i; i < _keyHolders.length; i++) {
            address keyHolder = _keyHolders[i];
            require(keyHolder != address(0), "Can't be zero address");
            require(!isKeyHolder[keyHolder], "Already registered as an owner!");
            isKeyHolder[keyHolder] = true;
            keyHolders.push(keyHolder);
        }
        token = _token;
        createTime = block.timestamp;
        lockedAmount = 280000000 * 10**18;
        unlockAmount[0] = 80000000 * 10**18;
        unlockAmount[1] = 56000000 * 10**18;
        unlockAmount[2] = 43400000 * 10**18;
        unlockAmount[3] = 43400000 * 10**18;
        unlockAmount[4] = 36400000 * 10**18;
        unlockAmount[5] = 20800000 * 10**18;
    }

    function setVesting(ERC20 _vestingContract) public onlyKeyHolder {
        vestingContract = _vestingContract;
        token.transfer(address(vestingContract), 10000000 * 10**18);
    }

    //This function uses the logic of 3 keyHolder wallets, so it will not find more than 1 non zero approval.
    function setApproveOrSend(address _toAddress, uint256 _amount)
        public
        onlyKeyHolder
    {
        require(
            _amount >= 0,
            "You can't set token approval amount to less than zero!"
        );
        require(
            _amount <= token.balanceOf(address(this)) - lockedAmount,
            "Can't send more than unlocked amount!"
        );
        approval[msg.sender][_toAddress] = _amount;
        if (_amount > 0) {
            for (uint256 i; i < keyHolders.length; i++) {
                if (keyHolders[i] == msg.sender) {
                    continue;
                }
                if (approval[keyHolders[i]][_toAddress] == _amount) {
                    approval[keyHolders[i]][_toAddress] = 0;
                    approval[msg.sender][_toAddress] = 0;
                    token.transfer(_toAddress, _amount);
                }
            }
        }
    }

    function unlockTerm() public {
        uint256 term = (block.timestamp - createTime) / (365 days);
        for (uint8 i = 0; i <= term && i <= 5; i++) {
            if (isTermUnlocked[i]) {
                continue;
            } else {
                isTermUnlocked[i] = true;
                lockedAmount -= unlockAmount[i];
                emit TermUnlocked(i, unlockAmount[i]);
            }
        }
    }

    function vest(address _to, uint256 _amount) public onlyKeyHolder {
        vestingContract.transfer(_to, _amount);
    }
}
