pragma solidity ^0.8.20;

import {Strings} from "@openzeppelin/5.3.0/utils/Strings.sol";
import {ERC721} from "@openzeppelin/5.3.0/token/ERC721/ERC721.sol";
import {AccessControl} from "@openzeppelin/5.3.0/access/AccessControl.sol";
import {SignaturesController} from "./modules/SignaturesController.sol";

contract QstmeGems is ERC721, AccessControl, SignaturesController {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    uint256 private nextTokenId;
    string private baseUri;
    mapping(uint256 tokenId => string uri) private tokenUris;

    uint256 public mintPrice;

    event MintPriceChanged(uint256 newPrice);
    event GemMinted(address receiver, uint256 tokenId);
    event TokenUriChanged(uint256 indexed tokenId, string newUri);
    event BaseUriChanged(string newUri);

    error NotEnoughPayment(uint256 received, uint256 expected);

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _mintPrice,
        string memory _baseUri,
        address _admin,
        address _operator
    ) ERC721(_name, _symbol) SignaturesController() {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(OPERATOR_ROLE, _operator);

        _setMintPrice(_mintPrice);
        _setBaseURI(_baseUri);
    }

    function claim(address _receiver, string calldata _uri, bytes calldata _signature) public payable returns(uint256) {
        _checkRole(OPERATOR_ROLE, _extractSigner(_receiver, _uri, _signature));
        if (msg.value < mintPrice) revert NotEnoughPayment(msg.value, mintPrice);

        uint256 tokenId = nextTokenId++;

        _mint(_receiver, tokenId);
        _setTokenURI(tokenId, _uri);

        emit GemMinted(_receiver, tokenId);

        return tokenId;
    }

    function setMintPrice(uint256 _newMintPrice) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setMintPrice(_newMintPrice);
    }

    function setTokenURI(uint256 _tokenId, string calldata _uri) public onlyRole(OPERATOR_ROLE) {
        _setTokenURI(_tokenId, _uri);
    }

    function setBaseURI(string calldata _uri) public onlyRole(OPERATOR_ROLE) {
        _setBaseURI(_uri);
    }

    function supportsInterface(bytes4 _interfaceId) public view override(AccessControl, ERC721) returns(bool) {
        return AccessControl.supportsInterface(_interfaceId)
            || ERC721.supportsInterface(_interfaceId);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);

        string memory baseURI = baseUri;
        return bytes(baseURI).length > 0 ? string.concat(baseURI, tokenUris[tokenId]) : "";
    }

    function _setMintPrice(uint256 _newMintPrice) internal {
        mintPrice = _newMintPrice;

        emit MintPriceChanged(_newMintPrice);
    }

    function _setTokenURI(uint256 _tokenId, string memory _uri) internal {
        _requireOwned(_tokenId);
        tokenUris[_tokenId] = _uri;

        emit TokenUriChanged(_tokenId, _uri);
    }

    function _setBaseURI(string memory _uri) internal {
        baseUri = _uri;

        emit BaseUriChanged(_uri);
    }

    function _nextTokenId() internal view returns(uint256) {
        return nextTokenId;
    }

    /**
     * @dev See {ERC721}.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }
}