// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Storage_SignaturesController} from "test/contracts/storage/Storage_SignaturesController.sol";

abstract contract Suite_SignaturesController is Storage_SignaturesController {
    function helper_sign(uint256 _privateKey, bytes32 _digest) public returns (bytes memory signature) {
        address signer = vm.addr(_privateKey);

        vm.startPrank(signer);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_privateKey, _digest);

        signature = abi.encodePacked(r, s, v);
        vm.stopPrank();
    }

    function test_Deployment(address _receiver) public view {
        assertEq(signatureController.receiverNonces(_receiver), 0);
    }

    function test_IncrementNonce_Ok(address _receiver, uint256 _startingNonce) public {
        vm.assume(_startingNonce < type(uint256).max);
        signatureController.helper_setNonce(_receiver, _startingNonce);

        vm.assertEq(signatureController.receiverNonces(_receiver), _startingNonce);

        signatureController.exposed_incrementNonce(_receiver);

        vm.assertEq(signatureController.receiverNonces(_receiver), _startingNonce + 1);
    }

    function test_GetNextNonce_Ok(address _receiver, uint256 _startingNonce) public {
        vm.assume(_startingNonce < type(uint256).max);
        signatureController.helper_setNonce(_receiver, _startingNonce);

        vm.assertEq(signatureController.receiverNonces(_receiver), _startingNonce);

        vm.assertEq(signatureController.exposed_getNextNonce(_receiver), _startingNonce + 1);
    }

    function test_ComposeClaimAllowanceDigest_Ok(address _receiver, string calldata _uri, uint256 _nonce) public view {
        bytes32 expectedDigest = signatureController.exposed_hashTypedDataV4(
            keccak256( abi.encode(
                SIGNATURE_STRUCT_HASH,
                _receiver,
                _uri,
                _nonce
            )));

        vm.assertEq(signatureController.exposed_composeClaimAllowanceDigest(_receiver, _uri, _nonce), expectedDigest);
    }

    function test_ComposeNextClaimAllowanceDigest_Ok(address _receiver, string calldata _uri, uint256 _startingNonce) public {
        vm.assume(_startingNonce < type(uint256).max);
        signatureController.helper_setNonce(_receiver, _startingNonce);

        bytes32 expectedDigest = signatureController.exposed_hashTypedDataV4(
            keccak256( abi.encode(
                SIGNATURE_STRUCT_HASH,
                _receiver,
                _uri,
                _startingNonce + 1
            )));

        vm.assertEq(signatureController.composeNextClaimAllowanceDigest(_receiver, _uri), expectedDigest);
    }

    function test_ExtractSigner(address _receiver, string calldata _uri, uint32 _signerIndex) public {
        (uint256 privateKey, address signer) = generateWallet(_signerIndex, "Signer");

        bytes32 digest = signatureController.composeNextClaimAllowanceDigest(_receiver, _uri);

        bytes memory signature = helper_sign(privateKey, digest);

        assertEq(signatureController.exposed_extractSigner(_receiver, _uri, signature), signer);
    }
}
