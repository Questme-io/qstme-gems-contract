// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Storage_SignaturesController} from "test/contracts/storage/Storage_SignaturesController.sol";

abstract contract Suite_SignaturesController_Claim is Storage_SignaturesController {
    function test_Claim_Deployment(address _receiver) public view {
        assertEq(signatureController.claimNonces(_receiver), 0);
    }

    function test_IncrementClaimNonce_Ok(address _receiver, uint256 _startingNonce) public {
        vm.assume(_startingNonce < type(uint256).max);
        signatureController.helper_setClaimNonce(_receiver, _startingNonce);

        vm.assertEq(signatureController.claimNonces(_receiver), _startingNonce);

        signatureController.exposed_incrementClaimNonce(_receiver);

        vm.assertEq(signatureController.claimNonces(_receiver), _startingNonce + 1);
    }

    function test_GetNextClaimNonce_Ok(address _receiver, uint256 _startingNonce) public {
        vm.assume(_startingNonce < type(uint256).max);
        signatureController.helper_setClaimNonce(_receiver, _startingNonce);

        vm.assertEq(signatureController.claimNonces(_receiver), _startingNonce);

        vm.assertEq(signatureController.exposed_getNextClaimNonce(_receiver), _startingNonce + 1);
    }

    function test_ComposeClaimAllowanceDigest_Ok(address _receiver, uint256 _tokenId, uint256 _nonce) public view {
        bytes32 expectedDigest = signatureController.exposed_hashTypedDataV4(
            keccak256(abi.encode(CLAIM_SIGNATURE_STRUCT_HASH, _receiver, _tokenId, _nonce))
        );

        vm.assertEq(
            signatureController.exposed_composeClaimAllowanceDigest(_receiver, _tokenId, _nonce), expectedDigest
        );
    }

    function test_ComposeNextClaimAllowanceDigest_Ok(address _receiver, uint256 _tokenId, uint256 _startingNonce)
        public
    {
        vm.assume(_startingNonce < type(uint256).max);
        signatureController.helper_setClaimNonce(_receiver, _startingNonce);

        bytes32 expectedDigest = signatureController.exposed_hashTypedDataV4(
            keccak256(abi.encode(CLAIM_SIGNATURE_STRUCT_HASH, _receiver, _tokenId, _startingNonce + 1))
        );

        vm.assertEq(signatureController.composeNextClaimAllowanceDigest(_receiver, _tokenId), expectedDigest);
    }

    function test_ExtractSigner(address _receiver, uint256 _tokenId, uint32 _signerIndex) public {
        (uint256 privateKey, address signer) = generateWallet(_signerIndex, "Signer");

        bytes32 digest = signatureController.composeNextClaimAllowanceDigest(_receiver, _tokenId);

        bytes memory signature = helper_sign(privateKey, digest);

        assertEq(signatureController.exposed_extractClaimSigner(_receiver, _tokenId, signature), signer);
    }
}
