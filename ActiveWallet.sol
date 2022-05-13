pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./Address.sol";
import "./ERC20.sol";
import "./Math.sol";
import "./IERC20.sol";

contract ActiveWallet{

    ERC20 public token;
    address[] public keyHolders;
    mapping(address => bool) public isKeyHolder;
    mapping(address => mapping(address => uint)) public approval;

    modifier onlyKeyHolder() {
        require(isKeyHolder[msg.sender],"Not a Key Holder!");
        _;
    }

    constructor(address[] memory _keyHolders){
        require(_keyHolders.length == 3,"There should be 3 adresses as keyHolders");
        for(uint i; i < _keyHolders.length; i++){
            address keyHolder = _keyHolders[i];
            require(keyHolder != address(0),"Can't be zero address");
            require(!isKeyHolder[keyHolder],"Already registered as an owner!");
            isKeyHolder[keyHolder] = true;
            keyHolders.push(keyHolder);
        }
    }
    //This function uses the logic of 3 keyHolder wallets, so it will not find more than 1 non zero approval.
    function setApproveOrSend(address _toAddress, uint _amount) public onlyKeyHolder {
        require(_amount >= 0,"You can't set token approval amount to less than zero!");
        approval[msg.sender][_toAddress] = _amount;
        if(_amount > 0){
            uint amountToSend=0;
            for(uint i; i < keyHolders.length; i++){
                if(keyHolders[i]==msg.sender){
                    continue;
                }
                if(approval[keyHolders[i]][_toAddress]>0){
                    amountToSend=approval[keyHolders[i]][_toAddress];
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

    

}