// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Safekeep {
    using SafeERC20 for IERC20;
    IERC20 public token;
    IERC20 public vestingContract;
    uint256 public lockedAmount;
    address[] public keyHolders;
    address public deployer;
    mapping(address => bool) public isKeyHolder;
    mapping(address => mapping(address => uint256)) public approval;
    uint256 public createTime;
    mapping(uint8 => bool) public isTermUnlocked;
    mapping(uint8 => uint256) public unlockAmount;
    event TermUnlocked(uint8 term, uint256 unlockedTokenWithTerm);
    event Approved(address keyHolder, address to, uint256 amount);
    event Sent(address to, uint256 amount);
    event Vested(address keyHolder, address to, uint256 amount);

    modifier onlyKeyHolder() {
        require(isKeyHolder[msg.sender], "Not a Key Holder!");
        _;
    }
    modifier onlyDeployer(){
      require(deployer == msg.sender, "Not Developer!");
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
        lockedAmount = 2800 * 10**(5+18);
        unlockAmount[0] = 800 * 10**(5+18);
        unlockAmount[1] = 560 * 10**(5+18);
        unlockAmount[2] = 434 * 10**(5+18);
        unlockAmount[3] = 434 * 10**(5+18);
        unlockAmount[4] = 364 * 10**(5+18);
        unlockAmount[5] = 208 * 10**(5+18);
    }

    function setVesting(ERC20 _vestingContract) external onlyDeployer {
        vestingContract = _vestingContract;
        token.safeTransfer(address(vestingContract), 100 * 10**(5+18));
    }
    function renounceDeployer() external onlyDeployer {
      deployer = address(0);
    }

    //This function uses the logic of 3 keyHolder wallets.
    function setApproveOrSend(address _toAddress, uint256 _amount)
        external
        onlyKeyHolder
    {
        require(_toAddress != address(0));
        require(
            _amount >= 0,
            "You can't set token approval amount to less than zero!"
        );
        require(
            _amount <= token.balanceOf(address(this)) - lockedAmount,
            "Can't send more than unlocked amount!"
        );
        approval[msg.sender][_toAddress] = _amount;
        emit Approved(msg.sender, _toAddress, _amount);
        if (_amount > 0) {
            for (uint256 i; i < keyHolders.length; i++) {
                if (keyHolders[i] == msg.sender) {
                    continue;
                }
                if (approval[keyHolders[i]][_toAddress] == _amount) {
                    approval[keyHolders[i]][_toAddress] = 0;
                    approval[msg.sender][_toAddress] = 0;
                    token.safeTransfer(_toAddress, _amount);
                    emit Sent(_toAddress, _amount);
                }
            }
        }
    }

    function unlockTerm() external {
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

    function vest(address _to, uint256 _amount) external onlyKeyHolder {
        vestingContract.safeTransfer(_to, _amount);
        emit Vested(msg.sender, _to, _amount);
    }
}
