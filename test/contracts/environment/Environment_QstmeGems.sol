// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Harness_QstmeGems} from "test/contracts/harness/Harness_QstmeGems.sol";
import {Storage_QstmeGems} from "test/contracts/storage/Storage_QstmeGems.sol";

abstract contract Environment_QstmeGems is Storage_QstmeGems {
    function _prepareEnv() internal override {
        qstmeGems = new Harness_QstmeGems();

        qstmeGems.initialize(defaultMintPrice, baseUri, admin, operator, minter);
    }
}
