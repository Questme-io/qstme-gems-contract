// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Harness_SignaturesController} from "test/contracts/harness/Harness_SignaturesController.sol";
import {Storage_SignaturesController} from "test/contracts/storage/Storage_SignaturesController.sol";

abstract contract Environment_SignaturesController is Storage_SignaturesController {
    function _prepareEnv() internal override {
        signatureController = new Harness_SignaturesController();
    }
}
