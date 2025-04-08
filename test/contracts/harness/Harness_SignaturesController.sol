// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {SignaturesController} from "src/modules/SignaturesController.sol";

contract Harness_SignaturesController is SignaturesController {
    function initialize() public initializer {
        __SignaturesController_init();
    }

    /// Claim functions

    function exposed_composeClaimAllowanceDigest(address _receiver, uint256 _tokenId, uint256 _nonce) public view returns(bytes32) {
        return _composeClaimAllowanceDigest(_receiver, _tokenId, _nonce);
    }

    function exposed_getNextClaimNonce(address _receiver) public view returns(uint256) {
        return _getNextClaimNonce(_receiver);
    }

    function exposed_incrementClaimNonce(address _receiver) public {
        _incrementClaimNonce(_receiver);
    }

    function exposed_extractClaimSigner(address _receiver, uint256 _tokenId, bytes calldata _signature) public view returns(address) {
        return _extractClaimSigner(_receiver, _tokenId, _signature);
    }

    function helper_setClaimNonce(address _receiver, uint256 _newNonce) public {
        claimNonces[_receiver] = _newNonce;
    }


    /// Update uri functions

    function exposed_composeUpdateUriAllowanceDigest(uint256 _tokenId, string calldata _uri, uint256 _nonce) public view returns(bytes32) {
        return _composeUpdateUriAllowanceDigest(_tokenId, _uri, _nonce);
    }

    function exposed_getNextUpdateUriNonce(uint256 _tokenId) public view returns(uint256) {
        return _getNextUpdateUriNonce(_tokenId);
    }

    function exposed_incrementUpdateUriNonce(uint256 _tokenId) public {
        _incrementUpdateUriNonce(_tokenId);
    }

    function exposed_extractUpdateUriSigner(uint256 _tokenId, string calldata _uri, bytes calldata _signature) public view returns(address) {
        return _extractUpdateUriSigner(_tokenId, _uri, _signature);
    }

    function helper_setUpdateUriNonce(uint256 _tokenId, uint256 _newNonce) public {
        updateUriNonces[_tokenId] = _newNonce;
    }

    /// Other functions

    function exposed_hashTypedDataV4(bytes32 data) public view returns(bytes32) {
        return _hashTypedDataV4(data);
    }
}
