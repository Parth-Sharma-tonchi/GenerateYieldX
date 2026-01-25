//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract MockUSDC is ERC20{
    constructor() ERC20("USD Coin", "USDC"){
        _mint(msg.sender, 1000000000e6);
    }

    function decimals() public pure override returns(uint8){
        return 6;
    }
}