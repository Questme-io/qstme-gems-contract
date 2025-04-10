// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Suite_QstmeGems} from "./suite/Suite_QstmeGems.sol";
import {Suite_QstmeGems_LazyClaim} from "./suite/Suite_QstmeGems_LazyClaim.sol";
import {Environment_QstmeGems} from "./environment/Environment_QstmeGems.sol";

contract Tester_QstmeGems is
Environment_QstmeGems,
Suite_QstmeGems
{}

contract Tester_QstmeGems_LazyClaim is
Environment_QstmeGems,
Suite_QstmeGems_LazyClaim
{}
