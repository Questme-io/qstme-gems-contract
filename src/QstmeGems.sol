pragma solidity ^0.8.20;

import {ERC1155Upgradeable} from "@openzeppelin/upgradeable/5.3.0/token/ERC1155/ERC1155Upgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/upgradeable/5.3.0/access/AccessControlUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/upgradeable/5.3.0/proxy/utils/UUPSUpgradeable.sol";
import {ERC1155SupplyUpgradeable} from "@openzeppelin/upgradeable/5.3.0/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import {ERC1155URIStorageUpgradeable} from "@openzeppelin/upgradeable/5.3.0/token/ERC1155/extensions/ERC1155URIStorageUpgradeable.sol";

import {SignaturesController} from "./modules/SignaturesController.sol";
import "./modules/WithdrawingController.sol";

contract QstmeGems is ERC1155Upgradeable, ERC1155SupplyUpgradeable, ERC1155URIStorageUpgradeable, AccessControlUpgradeable, SignaturesController, WithdrawingController, UUPSUpgradeable {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 public mintPrice;
    mapping(address user => mapping(uint256 tokenId => bool isMinted) tokenStatuses) public mintControl;

    event MintPriceChanged(uint256 newPrice);
    event GemMinted(address receiver, uint256 tokenId);
    event BaseUriChanged(string newUri);

    error NotEnoughPayment(uint256 received, uint256 expected);
    error AlreadyOwned(address receiver, uint256 tokenId);

    function initialize(
        uint256 _mintPrice,
        string memory _baseUri,
        address _admin,
        address _operator,
        address _minter
    ) public initializer {
        __AccessControl_init();
        __ERC1155_init(_baseUri);
        __ERC1155Supply_init();
        __ERC1155URIStorage_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(OPERATOR_ROLE, _operator);
        _grantRole(MINTER_ROLE, _minter);

        _setMintPrice(_mintPrice);
        _setBaseURI(_baseUri);
    }

    function supportsInterface(bytes4 _interfaceId) public view override(AccessControlUpgradeable, ERC1155Upgradeable) returns(bool) {
        return AccessControlUpgradeable.supportsInterface(_interfaceId)
            || ERC1155Upgradeable.supportsInterface(_interfaceId);
    }

    function uri(
        uint256 tokenId
    ) public view override(ERC1155Upgradeable, ERC1155URIStorageUpgradeable) returns (string memory) {
        return super.uri(tokenId);
    }

    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
        for (uint256 i = 0; i<ids.length; i++) {
            if (balanceOf(to, ids[i]) > 0) revert AlreadyOwned(to, ids[i]);
        }
        ERC1155SupplyUpgradeable._update(from, to, ids, values);
    }

    function claim(address _receiver, uint256 _tokenId, bytes calldata _signature) public payable {
        _checkRole(MINTER_ROLE, _extractClaimSigner(_receiver, _tokenId, _signature));
        _incrementClaimNonce(_receiver);

        if (msg.value < mintPrice) revert NotEnoughPayment(msg.value, mintPrice);

        _mint(_receiver, _tokenId, 1, "");

        mintControl[_receiver][_tokenId] = true;

        emit GemMinted(_receiver, _tokenId);
    }

    function lazyClaim(address _receiver, uint256 _tokenId, string calldata _uri, bytes calldata _claimSignature, bytes calldata _updateUriSignature) public payable {
        claim(_receiver, _tokenId, _claimSignature);

        if (updateUriNonces[_tokenId] == 0) {
            setTokenURI(_tokenId,  _uri, _updateUriSignature);
        }
    }

    function setMintPrice(uint256 _newMintPrice) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setMintPrice(_newMintPrice);
    }

    function setTokenURI(uint256 _tokenId, string calldata _uri, bytes calldata _signature) public {
        _checkRole(OPERATOR_ROLE, _extractUpdateUriSigner(_tokenId, _uri, _signature));
        _incrementUpdateUriNonce(_tokenId);

        _setURI(_tokenId, _uri);
    }

    function setBaseURI(string calldata _uri) public onlyRole(OPERATOR_ROLE) {
        _setBaseURI(_uri);

        emit BaseUriChanged(_uri);
    }

    function withdraw(address _receiver, Asset calldata _asset) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _withdraw(payable(_receiver), _asset);
    }

    function _setMintPrice(uint256 _newMintPrice) internal {
        mintPrice = _newMintPrice;

        emit MintPriceChanged(_newMintPrice);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(OPERATOR_ROLE) {}
}