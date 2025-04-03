// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {SignaturesController} from "src/modules/SignaturesController.sol";

contract Harness_SignaturesController is SignaturesController {
    constructor() SignaturesController() {}

    function exposed_composeClaimAllowanceDigest(address _receiver, string calldata _uri, uint256 _nonce) public view returns(bytes32) {
        return _composeClaimAllowanceDigest(_receiver, _uri, _nonce);
    }

    function exposed_getNextNonce(address _receiver) public view returns(uint256) {
        return _getNextNonce(_receiver);
    }

    function exposed_incrementNonce(address _receiver) public {
        _incrementNonce(_receiver);
    }

    function exposed_extractSigner(address _receiver, string calldata _uri, bytes calldata _signature) public view returns(address) {
        return _extractSigner(_receiver, _uri, _signature);
    }

    function exposed_hashTypedDataV4(bytes32 data) public view returns(bytes32) {
        return _hashTypedDataV4(data);
    }

    function helper_setNonce(address _receiver, uint256 _newNonce) public {
        receiverNonces[_receiver] = _newNonce;
    }
}
