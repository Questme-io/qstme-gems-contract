// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";

import {Harness_SignaturesController} from "test/contracts/harness/Harness_SignaturesController.sol";

abstract contract Storage_SignaturesController is Test {
    Harness_SignaturesController public signatureController;
    string public constant TEST_MNEMONIC = "test test test test test test test test test test test junk";

    function generateWallet(uint32 _id, string memory _name) public returns (uint256 privateKey, address addr) {
        privateKey = vm.deriveKey(TEST_MNEMONIC, _id);
        addr = vm.addr(privateKey);

        vm.label(addr, _name);
    }

    function _prepareEnv() internal virtual;

    function setUp() public virtual {
        _prepareEnv();
    }
}
