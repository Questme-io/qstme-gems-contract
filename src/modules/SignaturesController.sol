// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {EIP712} from "@openzeppelin/5.3.0/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/5.3.0/utils/cryptography/ECDSA.sol";

contract SignaturesController is EIP712 {
    string public constant NAME = "QstmeGems";
    string public constant VERSION = "0.1.0";
    bytes32 public constant SIGNATURE_STRUCT_HASH =
        keccak256("MintAllowance(address to, uint256 amount, bytes uri, uint256 nonce)");

    mapping(address receiver => uint256 nonce) public receiverNonces;

    event NonceUpdated(address indexed receiver, uint256 amount);

    constructor() EIP712(NAME, VERSION) {}

    function composeNextMintAllowanceDigest(address _receiver, bytes calldata _uri) public view returns(bytes32 digest) {
        return _composeMintAllowanceDigest(_receiver, _uri, _getNextNonce(_receiver));
    }

    function _getNextNonce(address _receiver) internal view returns(uint256) {
        return receiverNonces[_receiver] + 1;
    }

    function _composeMintAllowanceDigest(address _receiver, bytes calldata _uri, uint256 _nonce) internal view returns(bytes32 digest) {
        digest = _hashTypedDataV4(keccak256( abi.encode(
            SIGNATURE_STRUCT_HASH,
            _receiver,
            _uri,
            _nonce
        )));
    }

    function _incrementNonce(address _receiver) internal {
        uint256 newNonce = _getNextNonce(_receiver);
        receiverNonces[_receiver] = newNonce;

        emit NonceUpdated(_receiver, newNonce);
    }

    function _extractSigner(address _receiver, bytes calldata _uri, bytes calldata _signature) internal view returns(address) {
        bytes32 digest = composeNextMintAllowanceDigest(_receiver, _uri);

        return ECDSA.recover(digest, _signature);
    }
}
