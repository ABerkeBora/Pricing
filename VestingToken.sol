pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./Address.sol";
import "./ERC20.sol";
import "./Math.sol";
import "./IERC20.sol";

contract VestingToken is ERC20 {
    address safekeep;
    ERC20 token;
    mapping(address => uint256) private _vestings;
    uint public createTime;

    constructor(address _safekeep, ERC20 _token) ERC20("VoleVestingToken", "VVT") {
        safekeep = _safekeep;
        _mint(safekeep, 10000000);
        createTime=block.timestamp;
        token = _token;
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        require(to==address(this) || (owner==safekeep && to!=safekeep),"Only safekeep can transfer this token to another address!");
        if(owner==safekeep){
            _vestings[to]+=amount;
        }
        if(to==address(this)){
        require(_vestings[owner]-balanceOf(owner)+amount<=calculatePayback(owner),"Can't withdraw more until next vesting period.");
        token.transfer(to,amount);
        }
        _transfer(owner, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        require(to==address(this) || (from==safekeep && to!=safekeep),"Only safekeep can transfer this token to another address!");
        if(from==safekeep){
            _vestings[to]+=amount;
        }
        if(to==address(this)){
        require(_vestings[from]-balanceOf(from)+amount<=calculatePayback(from),"Can't withdraw more until next vesting period.");
        token.transfer(to,amount);
        }
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function calculatePayback(address from) public returns (uint256){
        uint256 timeAfterStartOfPay = block.timestamp-createTime-180 days;
        require(timeAfterStartOfPay>0);
        uint monthsPassed = timeAfterStartOfPay/30 days;
        if(monthsPassed>5){
            monthsPassed=5;
        }
       return _vestings[from]*monthsPassed/5;
    }

    
}