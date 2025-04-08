// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Suite_SignaturesController_Claim} from "./suite/Suite_SignaturesController_Claim.sol";
import {Suite_SignaturesController_UpdateUri} from "./suite/Suite_SignaturesController_UpdateUri.sol";
import {Environment_SignaturesController} from "./environment/Environment_SignaturesController.sol";

contract Tester_SignaturesController_Claim is
Environment_SignaturesController,
Suite_SignaturesController_Claim
    {}

contract Tester_SignaturesController_UpdateUri is
Environment_SignaturesController,
Suite_SignaturesController_UpdateUri
    {}
