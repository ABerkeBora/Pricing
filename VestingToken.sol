// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 *
 * This implementation is ERC20, could have just use the mappings for vested and recieved amounts
 * but we have wanted to have vesting tokens as ERC20 so users which only knows about metamask
 * or any basic wallet provider would have easier time (all they have to do is to transfer
 * their Vesting Token to the Vesting Contract to get back their original token)
 */
contract VestingToken is ERC20 {
    using SafeERC20 for IERC20;
    address public safekeep;
    IERC20 public token;
    mapping(address => uint256) private _vestings;
    uint256 public createTime;

    constructor(address _safekeep, ERC20 _token)
        ERC20("VoleVestingToken", "VVT")
    {
        safekeep = _safekeep;
        _mint(safekeep, 100 * 10**(5+18));
        createTime = block.timestamp;
        token = _token;
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        require(
            (owner != safekeep && to == address(this)) ||
                (owner == safekeep && to != safekeep),
            "Only safekeep can transfer this token to another address!"
        );
        if (owner == safekeep) {
            _vestings[to] += amount;
        }
        if (to == address(this)) {
            require(
                amount <= calculateAvailablePayback(owner),
                "Can't withdraw more until next vesting period."
            );
            token.safeTransfer(to, amount);
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
        require(
            (from != safekeep && to == address(this)) ||
                (from == safekeep && to != safekeep),
            "Only safekeep can transfer this token to another address!"
        );
        if (from == safekeep) {
            _vestings[to] += amount;
        }
        if (to == address(this)) {
            require(
                amount <= calculateAvailablePayback(from),
                "Can't withdraw more until next vesting period."
            );
            token.safeTransfer(to, amount);
        }
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function calculateTotalPayback(address _from)
        public
        view
        returns (uint256)
    {
        require(_from != address(0));
        uint256 timeAfterStartOfPay = block.timestamp - createTime - 180 days;
        require(
            timeAfterStartOfPay > 0,
            "This contract hasn't passed the cliff period yet!"
        );
        uint256 monthsPassed = timeAfterStartOfPay / 30 days;
        if (monthsPassed > 5) {
            monthsPassed = 5;
        }
        return (_vestings[_from] * monthsPassed) / 5;
    }

    function calculateAvailablePayback(address _from)
        public
        view
        returns (uint256)
    {
        require(_from != address(0));
        return
            calculateTotalPayback(_from) -
            (_vestings[_from] - balanceOf(_from));
    }
}
