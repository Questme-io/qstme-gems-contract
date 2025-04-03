// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";

import {Harness_QstmeGems} from "test/contracts/harness/Harness_QstmeGems.sol";

abstract contract Storage_QstmeGems is Test {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    string public constant TEST_MNEMONIC = "test test test test test test test test test test test junk";

    string public name = "Qstme Gems";
    string public symbol = "QGS";
    uint256 public mintPrice = 1e9;
    string public baseUri = "baseUri://";

    address public admin = address(1);
    address public operator = address(1);

    Harness_QstmeGems public qstmeGems;

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
