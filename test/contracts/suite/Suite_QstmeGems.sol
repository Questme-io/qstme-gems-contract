// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {IAccessControl} from "@openzeppelin/5.3.0/access/IAccessControl.sol";
import {IERC721Errors} from "@openzeppelin/5.3.0/interfaces/draft-IERC6093.sol";

import {QstmeGems} from "src/QstmeGems.sol";
import {Storage_QstmeGems} from "test/contracts/storage/Storage_QstmeGems.sol";

abstract contract Suite_QstmeGems is Storage_QstmeGems {
    function helper_sign(uint256 _privateKey, bytes32 _digest) public returns (bytes memory signature) {
        address signer = vm.addr(_privateKey);

        vm.startPrank(signer);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_privateKey, _digest);

        signature = abi.encodePacked(r, s, v);
        vm.stopPrank();
    }

    function toComparable(string memory _str) public pure returns(bytes32) {
        return keccak256(abi.encode(_str));
    }

    function test_Deployment(address _receiver) public view {
        vm.assume(_receiver != address(0));
        assertEq(qstmeGems.balanceOf(_receiver), 0);
        assertEq(toComparable(qstmeGems.name()), toComparable(name));
        assertEq(toComparable(qstmeGems.symbol()), toComparable(symbol));
        assertTrue(qstmeGems.hasRole(DEFAULT_ADMIN_ROLE, admin));
        assertTrue(qstmeGems.hasRole(OPERATOR_ROLE, operator));
        assertEq(qstmeGems.mintPrice(), mintPrice);
    }

    function test_Claim_Ok(address _receiver, string calldata _uri, uint32 operatorIndex) public {
        vm.assume(_receiver != address(0));

        (uint256 operatorPK, address operator) = generateWallet(operatorIndex, "Operator");

        qstmeGems.helper_grantRole(OPERATOR_ROLE, operator);

        bytes32 digest = qstmeGems.composeNextClaimAllowanceDigest(_receiver, _uri);

        bytes memory signature = helper_sign(operatorPK, digest);

        uint256 tokenId = qstmeGems.exposed_nextTokenId();

        vm.expectEmit();
        emit QstmeGems.GemMinted(_receiver, tokenId);

        qstmeGems.claim{ value: qstmeGems.mintPrice() }(_receiver, _uri, signature);

        vm.assertEq(qstmeGems.exposed_nextTokenId(), tokenId + 1);
        vm.assertEq(qstmeGems.balanceOf(_receiver), 1);
        vm.assertEq(qstmeGems.ownerOf(tokenId), _receiver);
        vm.assertEq(toComparable(qstmeGems.tokenURI(tokenId)), toComparable(string.concat(qstmeGems.exposed_baseUri(), _uri)));
    }

    function test_Claim_Revert_IfSignerIsNotAnOperator(address _receiver, string calldata _uri, uint32 signerIndex) public {
        vm.assume(_receiver != address(0));

        (uint256 signerPK, address signer) = generateWallet(signerIndex, "Signer");

        bytes32 digest = qstmeGems.composeNextClaimAllowanceDigest(_receiver, _uri);

        bytes memory signature = helper_sign(signerPK, digest);

        uint256 tokenId = qstmeGems.exposed_nextTokenId();

        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                signer,
                OPERATOR_ROLE
            )
        );

        qstmeGems.claim{ value: mintPrice }(_receiver, _uri, signature);

        vm.assertEq(qstmeGems.exposed_nextTokenId(), tokenId);
        vm.assertEq(qstmeGems.balanceOf(_receiver), 0);
    }

    function test_Claim_Revert_IfDigestIsInvalid(address _receiver, address _receiverDigest, string calldata _uri, uint32 operatorIndex) public {
        vm.assume(_receiver != address(0));
        vm.assume(_receiver != _receiverDigest);

        (uint256 operatorPK,) = generateWallet(operatorIndex, "Operator");

        bytes32 digest = qstmeGems.composeNextClaimAllowanceDigest(_receiverDigest, _uri);

        bytes memory signature = helper_sign(operatorPK, digest);

        uint256 tokenId = qstmeGems.exposed_nextTokenId();

        vm.expectPartialRevert(IAccessControl.AccessControlUnauthorizedAccount.selector);

        qstmeGems.claim{ value: mintPrice }(_receiver, _uri, signature);

        vm.assertEq(qstmeGems.exposed_nextTokenId(), tokenId);
        vm.assertEq(qstmeGems.balanceOf(_receiver), 0);
    }

    function test_Claim_Revert_IfPaymentIsNotOk(uint256 _payment, address _receiver, string calldata _uri, uint32 operatorIndex) public {
        vm.assume(_payment < qstmeGems.mintPrice());
        vm.assume(_receiver != address(0));

        (uint256 operatorPK, address operator) = generateWallet(operatorIndex, "Operator");

        qstmeGems.helper_grantRole(OPERATOR_ROLE, operator);

        bytes32 digest = qstmeGems.composeNextClaimAllowanceDigest(_receiver, _uri);

        bytes memory signature = helper_sign(operatorPK, digest);

        uint256 tokenId = qstmeGems.exposed_nextTokenId();

        vm.expectRevert(
            abi.encodeWithSelector(
                QstmeGems.NotEnoughPayment.selector,
                _payment,
                qstmeGems.mintPrice()
            )
        );

        qstmeGems.claim{ value: _payment }(_receiver, _uri, signature);

        vm.assertEq(qstmeGems.exposed_nextTokenId(), tokenId);
        vm.assertEq(qstmeGems.balanceOf(_receiver), 0);
    }

    function test_SetMintPrice_Ok(address _admin, uint256 _newMintPrice) public {
        vm.assume(_admin != address(0));

        qstmeGems.helper_grantRole(DEFAULT_ADMIN_ROLE, _admin);

        vm.expectEmit();
        emit QstmeGems.MintPriceChanged(_newMintPrice);

        vm.prank(admin);
        qstmeGems.setMintPrice(_newMintPrice);

        vm.assertEq(qstmeGems.mintPrice(), _newMintPrice);
    }

    function test_SetMintPrice_Revert_IfCallerIsNotAnAdmin(address _anonym, uint256 _newMintPrice) public {
        vm.assume(_anonym != address(0));
        vm.assume(!qstmeGems.hasRole(DEFAULT_ADMIN_ROLE, _anonym));

        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                _anonym,
                DEFAULT_ADMIN_ROLE
            )
        );

        vm.prank(_anonym);
        qstmeGems.setMintPrice(_newMintPrice);
    }

    function test_SetTokenUri_Ok(address _operator, string calldata _newTokenUri) public {
        vm.assume(_operator != address(0));

        qstmeGems.helper_grantRole(OPERATOR_ROLE, _operator);

        uint256 tokenId = qstmeGems.helper_mint(_operator);

        vm.expectEmit();
        emit QstmeGems.TokenUriChanged(tokenId, _newTokenUri);

        vm.prank(_operator);
        qstmeGems.setTokenURI(tokenId, _newTokenUri);

        vm.assertEq(toComparable(qstmeGems.tokenURI(tokenId)), toComparable(string.concat(qstmeGems.exposed_baseUri(), _newTokenUri)));
    }

    function test_SetTokenUri_Revert_IfCallerIsNotAnOperator(address _anonym, string calldata _newTokenUri) public {
        vm.assume(_anonym != address(0));
        vm.assume(!qstmeGems.hasRole(OPERATOR_ROLE, _anonym));

        uint256 tokenId = qstmeGems.helper_mint(_anonym);

        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                _anonym,
                OPERATOR_ROLE
            )
        );

        vm.prank(_anonym);
        qstmeGems.setTokenURI(tokenId, _newTokenUri);
    }

    function test_SetTokenUri_Revert_IfTokenIsNotMinted(address _operator, uint256 _tokenId, string calldata _newTokenUri) public {
        vm.assume(_operator != address(0));

        qstmeGems.helper_grantRole(OPERATOR_ROLE, _operator);

        vm.expectRevert(
            abi.encodeWithSelector(
                IERC721Errors.ERC721NonexistentToken.selector,
                _tokenId
            )
        );

        vm.prank(_operator);
        qstmeGems.setTokenURI(_tokenId, _newTokenUri);
    }

    function test_SetBaseUri_Ok(address _operator, string calldata _newBaseUri) public {
        vm.assume(_operator != address(0));

        qstmeGems.helper_grantRole(OPERATOR_ROLE, _operator);

        vm.expectEmit();
        emit QstmeGems.BaseUriChanged(_newBaseUri);

        vm.prank(admin);
        qstmeGems.setBaseURI(_newBaseUri);

        vm.assertEq(toComparable(qstmeGems.exposed_baseUri()), toComparable(_newBaseUri));
    }

    function test_SetBaseUri_Revert_IfCallerIsNotAnOperator(address _anonym, string calldata _newBaseUri) public {
        vm.assume(_anonym != address(0));
        vm.assume(!qstmeGems.hasRole(OPERATOR_ROLE, _anonym));

        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                _anonym,
                OPERATOR_ROLE
            )
        );

        vm.prank(_anonym);
        qstmeGems.setBaseURI(_newBaseUri);
    }
}
