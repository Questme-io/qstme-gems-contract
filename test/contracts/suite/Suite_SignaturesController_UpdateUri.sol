// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Storage_SignaturesController} from "test/contracts/storage/Storage_SignaturesController.sol";

abstract contract Suite_SignaturesController_UpdateUri is Storage_SignaturesController {
    function test_UpdateUri_Deployment(uint256 _tokenId) public view {
        assertEq(signatureController.updateUriNonces(_tokenId), 0);
    }

    function test_IncrementUpdateUriNonce_Ok(uint256 _tokenId, uint256 _startingNonce) public {
        vm.assume(_startingNonce < type(uint256).max);
        signatureController.helper_setUpdateUriNonce(_tokenId, _startingNonce);

        vm.assertEq(signatureController.updateUriNonces(_tokenId), _startingNonce);

        signatureController.exposed_incrementUpdateUriNonce(_tokenId);

        vm.assertEq(signatureController.updateUriNonces(_tokenId), _startingNonce + 1);
    }

    function test_GetNextUpdateUriNonce_Ok(uint256 _tokenId, uint256 _startingNonce) public {
        vm.assume(_startingNonce < type(uint256).max);
        signatureController.helper_setUpdateUriNonce(_tokenId, _startingNonce);

        vm.assertEq(signatureController.updateUriNonces(_tokenId), _startingNonce);

        vm.assertEq(signatureController.exposed_getNextUpdateUriNonce(_tokenId), _startingNonce + 1);
    }

    function test_ComposeUpdateUriAllowanceDigest_Ok(uint256 _tokenId, string calldata _uri, uint256 _nonce)
        public
        view
    {
        bytes32 expectedDigest = signatureController.exposed_hashTypedDataV4(
            keccak256(abi.encode(UPDATE_URI_SIGNATURE_STRUCT_HASH, _tokenId, _uri, _nonce))
        );

        vm.assertEq(signatureController.exposed_composeUpdateUriAllowanceDigest(_tokenId, _uri, _nonce), expectedDigest);
    }

    function test_ComposeNextUpdateUriAllowanceDigest_Ok(uint256 _tokenId, string calldata _uri, uint256 _startingNonce)
        public
    {
        vm.assume(_startingNonce < type(uint256).max);
        signatureController.helper_setUpdateUriNonce(_tokenId, _startingNonce);

        bytes32 expectedDigest = signatureController.exposed_hashTypedDataV4(
            keccak256(abi.encode(UPDATE_URI_SIGNATURE_STRUCT_HASH, _tokenId, _uri, _startingNonce + 1))
        );

        vm.assertEq(signatureController.composeNextUpdateUriAllowanceDigest(_tokenId, _uri), expectedDigest);
    }

    function test_ExtractUpdateUriSigner(uint256 _tokenId, string calldata _uri, uint32 _signerIndex) public {
        (uint256 privateKey, address signer) = generateWallet(_signerIndex, "Signer");

        bytes32 digest = signatureController.composeNextUpdateUriAllowanceDigest(_tokenId, _uri);

        bytes memory signature = helper_sign(privateKey, digest);

        assertEq(signatureController.exposed_extractUpdateUriSigner(_tokenId, _uri, signature), signer);
    }
}
