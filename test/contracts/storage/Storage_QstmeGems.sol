// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";

import {Mock_ERC20} from "test/contracts/mock/Mock_ERC20.sol";
import {Harness_QstmeGems} from "test/contracts/harness/Harness_QstmeGems.sol";

abstract contract Storage_QstmeGems is Test {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    string public constant TEST_MNEMONIC = "test test test test test test test test test test test junk";

    uint256 public defaultMintPrice = 1e9;
    string public baseUri = "baseUri://";

    address public admin = address(1);
    address public operator = address(2);
    address public minter = address(3);

    Harness_QstmeGems public qstmeGems;

    function deployERC20(address _address) public {
        Mock_ERC20 _erc20 = new Mock_ERC20("ERC20", "ERC20");
        vm.etch(_address, address(_erc20).code);
    }

    function generateWallet(uint32 _id, string memory _name) public returns (uint256 privateKey, address addr) {
        privateKey = vm.deriveKey(TEST_MNEMONIC, _id);
        addr = vm.addr(privateKey);

        vm.label(addr, _name);
    }

    function helper_sign(uint256 _privateKey, bytes32 _digest) public returns (bytes memory signature) {
        address signer = vm.addr(_privateKey);

        vm.startPrank(signer);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_privateKey, _digest);

        signature = abi.encodePacked(r, s, v);
        vm.stopPrank();
    }

    function toComparable(string memory _str) public pure returns (bytes32) {
        return keccak256(abi.encode(_str));
    }

    function _prepareEnv() internal virtual;

    function setUp() public virtual {
        _prepareEnv();
    }
}
