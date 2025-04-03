// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {QstmeGems} from "src/QstmeGems.sol";

contract Harness_QstmeGems is QstmeGems {
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _mintPrice,
        string memory _baseUri,
        address _admin,
        address _operator
    ) QstmeGems(_name, _symbol, _mintPrice, _baseUri, _admin, _operator) {}

    function exposed_setMintPrice(uint256 _newMintPrice) public {
        _setMintPrice(_newMintPrice);
    }

    function exposed_setTokenURI(uint256 _tokenId, string calldata _uri) public {
        _setTokenURI(_tokenId, _uri);
    }

    function exposed_setBaseURI(string calldata _uri) public {
        _setBaseURI(_uri);
    }

    function exposed_nextTokenId() public view returns(uint256) {
        return _nextTokenId();
    }

    function exposed_baseUri() public view returns(string memory) {
        return _baseURI();
    }

    function helper_mint(address _receiver) public returns(uint256) {
        uint256 tokenId = _nextTokenId();

        _mint(_receiver, tokenId);

        return tokenId;
    }

    function helper_grantRole(bytes32 _role, address _account) public {
        _grantRole(_role, _account);
    }

    function helper_revokeRole(bytes32 _role, address _account) public {
        _revokeRole(_role, _account);
    }
}
