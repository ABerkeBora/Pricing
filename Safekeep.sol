pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./Address.sol";
import "./ERC20.sol";
import "./Math.sol";
import "./IERC20.sol";

contract Safekeep{

    ERC20 public token;
    ERC20 public vestingContract;
    //Implemented lockedAmount instead of unlockedAmount to work around the exploits which would be possible by sending tokens back to this contract.
    uint public lockedAmount;
    address[] public keyHolders;
    mapping(address => bool) public isKeyHolder;
    uint public required;
    mapping(address => mapping(address => uint)) public approval;
    uint public createTime;
    mapping(uint8=>bool) public isTermUnlocked;
    mapping(uint8=>uint) public unlockAmount;
    event TermUnlocked(uint8 term, uint256 unlockedTokenWithTerm);


    modifier onlyKeyHolder() {
        require(isKeyHolder[msg.sender],"Not a Key Holder!");
        _;
    }

    constructor(address[] memory _keyHolders,ERC20 _token){
        require(_keyHolders.length == 3,"There should be 3 adresses as keyHolders");
        for(uint i; i < _keyHolders.length; i++){
            address keyHolder = _keyHolders[i];
            require(keyHolder != address(0),"Can't be zero address");
            require(!isKeyHolder[keyHolder],"Already registered as an owner!");
            isKeyHolder[keyHolder] = true;
            keyHolders.push(keyHolder);
        }
        token=_token;
        createTime = block.timestamp;
        lockedAmount = 280000000;
        unlockAmount[0] = 80000000;
        unlockAmount[1] = 56000000;
        unlockAmount[2] = 43400000;
        unlockAmount[3] = 43400000;
        unlockAmount[4] = 36400000;
        unlockAmount[5] = 20800000;
    }

    function setVesting(ERC20 _vestingContract) public onlyKeyHolder {
        vestingContract = _vestingContract;
        token.transfer(address(vestingContract), 10000000);
    }


    //This function uses the logic of 3 keyHolder wallets, so it will not find more than 1 non zero approval.
    function setApproveOrSend(address _toAddress, uint _amount) public onlyKeyHolder {
        require(_amount >= 0,"You can't set token approval amount to less than zero!");
        require(_amount <= token.balanceOf(address(this))-lockedAmount,"Can't send more than unlocked amount!");
        approval[msg.sender][_toAddress] = _amount;
        if(_amount > 0){
            uint amountToSend=0;
            for(uint i; i < keyHolders.length; i++){
                if(keyHolders[i]==msg.sender){
                    continue;
                }
                if(approval[keyHolders[i]][_toAddress]>0){
                    amountToSend=approval[keyHolders[i]][_toAddress];
                    require(amountToSend <= token.balanceOf(address(this))-lockedAmount,"Can't send more than unlocked amount!");
                        if(_amount>amountToSend){
                            approval[keyHolders[i]][_toAddress]=0;
                            approval[msg.sender][_toAddress]=_amount-amountToSend;
                            token.transfer(_toAddress, amountToSend);
                        }else{
                            approval[msg.sender][_toAddress]=0;
                            approval[keyHolders[i]][_toAddress]=amountToSend-_amount;
                            token.transfer(_toAddress, _amount);
                        }
                }
            }
        }
        

    }
    function unlockTerm() public {
        uint term=(block.timestamp - createTime)/(365 days);
        for(uint8 i = 0; i <= term && i <=5; i++){
            if(isTermUnlocked[i]){
                continue;
            }else{
                isTermUnlocked[i] = true;
                lockedAmount -= unlockAmount[i];
                emit TermUnlocked(i,unlockAmount[i]);
            }
        }
        
    }

    function vest(address to, uint256 amount) public onlyKeyHolder{
        vestingContract.transfer(to, amount);
    }

    

}