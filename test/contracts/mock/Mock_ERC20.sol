// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {ERC20} from "@openzeppelin/5.3.0/token/ERC20/ERC20.sol";

contract Mock_ERC20 is ERC20 {
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}
}
