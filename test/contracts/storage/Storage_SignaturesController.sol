// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";

import {Harness_SignaturesController} from "test/contracts/harness/Harness_SignaturesController.sol";

abstract contract Storage_SignaturesController is Test {
    Harness_SignaturesController public signatureController;
    string public constant TEST_MNEMONIC = "test test test test test test test test test test test junk";
    bytes32 public constant CLAIM_SIGNATURE_STRUCT_HASH =
        keccak256("ClaimAllowance(address to, uint256 tokenId, uint256 nonce)");
    bytes32 public constant UPDATE_URI_SIGNATURE_STRUCT_HASH =
        keccak256("UpdateUriAllowance(uint256 tokenId, string uri, uint256 nonce)");

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

    function _prepareEnv() internal virtual;

    function setUp() public virtual {
        _prepareEnv();
    }
}
