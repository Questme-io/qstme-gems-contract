// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {EIP712Upgradeable} from "@openzeppelin/upgradeable/5.3.0/utils/cryptography/EIP712Upgradeable.sol";
import {ECDSA} from "@openzeppelin/5.3.0/utils/cryptography/ECDSA.sol";

contract SignaturesController is EIP712Upgradeable {
    string private constant NAME = "QstmeGems";
    string private constant VERSION = "0.1.0";
    bytes32 private constant CLAIM_SIGNATURE_STRUCT_HASH =
        keccak256("ClaimAllowance(address to, uint256 tokenId, uint256 nonce)");
    bytes32 private constant UPDATE_URI_SIGNATURE_STRUCT_HASH =
        keccak256("UpdateUriAllowance(uint256 tokenId, string uri, uint256 nonce)");

    mapping(address receiver => uint256 nonce) public claimNonces;
    mapping(uint256 tokenId => uint256 nonce) public updateUriNonces;

    event ClaimNonceUpdated(address indexed receiver, uint256 updatedNonce);
    event UpdateUriNonceUpdated(uint256 indexed tokenId, uint256 updatedNonce);

    function __SignaturesController_init() internal {
        __EIP712_init(NAME, VERSION);
    }

    function composeNextClaimAllowanceDigest(address _receiver, uint256 _tokenId) public view returns(bytes32 digest) {
        return _composeClaimAllowanceDigest(_receiver, _tokenId, _getNextClaimNonce(_receiver));
    }

    function composeNextUpdateUriAllowanceDigest(uint256 _tokenId, string calldata _uri) public view returns(bytes32 digest) {
        return _composeUpdateUriAllowanceDigest(_tokenId, _uri, _getNextUpdateUriNonce(_tokenId));
    }

    function _composeClaimAllowanceDigest(address _receiver, uint256 _tokenId, uint256 _nonce) internal view returns(bytes32 digest) {
        digest = _hashTypedDataV4(keccak256( abi.encode(
            CLAIM_SIGNATURE_STRUCT_HASH,
            _receiver,
            _tokenId,
            _nonce
        )));
    }

    function _composeUpdateUriAllowanceDigest(uint256 _tokenId, string calldata _uri, uint256 _nonce) internal view returns(bytes32 digest) {
        digest = _hashTypedDataV4(keccak256( abi.encode(
            UPDATE_URI_SIGNATURE_STRUCT_HASH,
            _tokenId,
            _uri,
            _nonce
        )));
    }

    function _getNextClaimNonce(address _receiver) internal view returns(uint256) {
        return claimNonces[_receiver] + 1;
    }

    function _getNextUpdateUriNonce(uint256 _tokenId) internal view returns(uint256) {
        return updateUriNonces[_tokenId] + 1;
    }

    function _incrementClaimNonce(address _receiver) internal {
        uint256 newNonce = _getNextClaimNonce(_receiver);
        claimNonces[_receiver] = newNonce;

        emit ClaimNonceUpdated(_receiver, newNonce);
    }

    function _incrementUpdateUriNonce(uint256 _tokenId) internal {
        uint256 newNonce = _getNextUpdateUriNonce(_tokenId);
        updateUriNonces[_tokenId] = newNonce;

        emit UpdateUriNonceUpdated(_tokenId, newNonce);
    }

    function _extractClaimSigner(address _receiver, uint256 _tokenId, bytes calldata _signature) internal view returns(address) {
        bytes32 digest = composeNextClaimAllowanceDigest(_receiver, _tokenId);

        return ECDSA.recover(digest, _signature);
    }

    function _extractUpdateUriSigner(uint256 _tokenId, string calldata _uri, bytes calldata _signature) internal view returns(address) {
        bytes32 digest = composeNextUpdateUriAllowanceDigest(_tokenId, _uri);

        return ECDSA.recover(digest, _signature);
    }
}
