// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {QstmeGems} from "src/QstmeGems.sol";

contract Harness_QstmeGems is QstmeGems {
    function exposed_setDefaultMintPrice(uint256 _newDefaultMintPrice) public {
        _setDefaultMintPrice(_newDefaultMintPrice);
    }

    function exposed_setBaseURI(string calldata _uri) public {
        _setBaseURI(_uri);
    }

    function exposed_setTokenURI(uint256 _tokenId, string calldata _uri) public {
        _setURI(_tokenId, _uri);
    }

    function helper_mint(address _receiver, uint256 _tokenId) public {
        _mint(_receiver, _tokenId, 1, "");
    }

    function helper_grantRole(bytes32 _role, address _account) public {
        _grantRole(_role, _account);
    }

    function helper_revokeRole(bytes32 _role, address _account) public {
        _revokeRole(_role, _account);
    }
}
