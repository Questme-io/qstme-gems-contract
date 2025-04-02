// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Suite_SignaturesController} from "./suite/Suite_SignaturesController.sol";
import {Environment_SignaturesController} from "./environment/Environment_SignaturesController.sol";

contract Tester_QstmeSponsor is
Environment_SignaturesController,
Suite_SignaturesController
    {}
