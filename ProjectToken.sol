//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ProjectToken is ERC20 {
    constructor() ERC20("ProjectToken", "PRT") {
        _mint(msg.sender, 2800 * 10**(5+decimals()));
    }
}
