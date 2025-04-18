// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {IAccessControl} from "@openzeppelin/5.3.0/access/IAccessControl.sol";
import {IERC1155} from "@openzeppelin/5.3.0/token/ERC1155/IERC1155.sol";

import "src/modules/WithdrawingController.sol";
import {QstmeGems} from "src/QstmeGems.sol";
import {Storage_QstmeGems} from "test/contracts/storage/Storage_QstmeGems.sol";

abstract contract Suite_QstmeGems is Storage_QstmeGems {
    function test_Deployment(address _receiver, uint256 _tokenId) public view {
        vm.assume(_receiver != address(0));
        assertEq(qstmeGems.balanceOf(_receiver, _tokenId), 0);
        assertTrue(qstmeGems.hasRole(DEFAULT_ADMIN_ROLE, admin));
        assertTrue(qstmeGems.hasRole(OPERATOR_ROLE, operator));
        assertFalse(qstmeGems.mintControl(_receiver, _tokenId));
        assertEq(qstmeGems.mintPrice(), mintPrice);
    }

    function test_Claim_Ok(address _receiver, uint256 _tokenId, uint32 minterIndex) public {
        assumeUnusedAddress(_receiver);

        (uint256 minterPK, address minter) = generateWallet(minterIndex, "Minter");

        qstmeGems.helper_grantRole(MINTER_ROLE, minter);

        bytes32 digest = qstmeGems.composeNextClaimAllowanceDigest(_receiver, _tokenId);

        bytes memory signature = helper_sign(minterPK, digest);
        uint256 balanceBefore = address(qstmeGems).balance;

        vm.expectEmit();
        emit QstmeGems.GemMinted(_receiver, _tokenId);

        qstmeGems.claim{ value: qstmeGems.mintPrice() }(_receiver, _tokenId, signature);

        vm.assertEq(qstmeGems.balanceOf(_receiver, _tokenId), 1);
        assertTrue(qstmeGems.mintControl(_receiver, _tokenId));
        vm.assertEq(address(qstmeGems).balance, balanceBefore + qstmeGems.mintPrice());
    }

    function test_Claim_Revert_IfMintingSameGemSecondTime(address _receiver, uint256 _tokenId, uint32 minterIndex) public {
        assumeUnusedAddress(_receiver);

        (uint256 minterPK, address minter) = generateWallet(minterIndex, "Minter");

        qstmeGems.helper_grantRole(MINTER_ROLE, minter);

        bytes32 digest = qstmeGems.composeNextClaimAllowanceDigest(_receiver, _tokenId);

        bytes memory signature = helper_sign(minterPK, digest);
        uint256 balanceBefore = address(qstmeGems).balance;
        uint256 mintPrice = qstmeGems.mintPrice();

        vm.expectEmit();
        emit QstmeGems.GemMinted(_receiver, _tokenId);

        qstmeGems.claim{ value: mintPrice }(_receiver, _tokenId, signature);

        digest = qstmeGems.composeNextClaimAllowanceDigest(_receiver, _tokenId);

        signature = helper_sign(minterPK, digest);

        vm.expectRevert(abi.encodeWithSelector(
            QstmeGems.AlreadyOwned.selector,
            _receiver,
            _tokenId
        ));

        qstmeGems.claim{ value: mintPrice }(_receiver, _tokenId, signature);

        vm.assertEq(qstmeGems.balanceOf(_receiver, _tokenId), 1);
        assertTrue(qstmeGems.mintControl(_receiver, _tokenId));
        vm.assertEq(address(qstmeGems).balance, balanceBefore + mintPrice);
    }

    function test_Claim_Revert_IfSignerIsNotAMinter(address _receiver, uint256 _tokenId, uint32 signerIndex) public {
        vm.assume(_receiver != address(0));

        (uint256 signerPK, address signer) = generateWallet(signerIndex, "Signer");

        bytes32 digest = qstmeGems.composeNextClaimAllowanceDigest(_receiver, _tokenId);

        bytes memory signature = helper_sign(signerPK, digest);
        uint256 balanceBefore = address(qstmeGems).balance;

        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                signer,
                MINTER_ROLE
            )
        );

        qstmeGems.claim{ value: mintPrice }(_receiver, _tokenId, signature);

        vm.assertEq(qstmeGems.balanceOf(_receiver, _tokenId), 0);
        assertFalse(qstmeGems.mintControl(_receiver, _tokenId));
        vm.assertEq(address(qstmeGems).balance, balanceBefore);
    }

    function test_Claim_Revert_IfDigestIsInvalid(address _receiver, address _receiverDigest, uint256 _tokenId, uint32 minterIndex) public {
        vm.assume(_receiver != address(0));
        vm.assume(_receiver != _receiverDigest);

        (uint256 minterPK, address minter) = generateWallet(minterIndex, "Minter");

        qstmeGems.helper_grantRole(MINTER_ROLE, minter);

        bytes32 digest = qstmeGems.composeNextClaimAllowanceDigest(_receiverDigest, _tokenId);

        bytes memory signature = helper_sign(minterPK, digest);
        uint256 balanceBefore = address(qstmeGems).balance;

        vm.expectPartialRevert(IAccessControl.AccessControlUnauthorizedAccount.selector);

        qstmeGems.claim{ value: mintPrice }(_receiver, _tokenId, signature);

        vm.assertEq(qstmeGems.balanceOf(_receiver, _tokenId), 0);
        assertFalse(qstmeGems.mintControl(_receiver, _tokenId));
        vm.assertEq(address(qstmeGems).balance, balanceBefore);
    }

    function test_Claim_Revert_IfPaymentIsNotOk(uint256 _payment, address _receiver, uint256 _tokenId, uint32 minterIndex) public {
        vm.assume(_payment < qstmeGems.mintPrice());
        vm.assume(_receiver != address(0));

        (uint256 minterPK, address minter) = generateWallet(minterIndex, "Minter");

        qstmeGems.helper_grantRole(MINTER_ROLE, minter);

        bytes32 digest = qstmeGems.composeNextClaimAllowanceDigest(_receiver, _tokenId);

        bytes memory signature = helper_sign(minterPK, digest);

        vm.expectRevert(
            abi.encodeWithSelector(
                QstmeGems.NotEnoughPayment.selector,
                _payment,
                qstmeGems.mintPrice()
            )
        );

        qstmeGems.claim{ value: _payment }(_receiver, _tokenId, signature);

        vm.assertEq(qstmeGems.balanceOf(_receiver, _tokenId), 0);
        assertFalse(qstmeGems.mintControl(_receiver, _tokenId));
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

    function test_SetTokenUri_Ok(uint256 _tokenId, string calldata _newTokenUri, uint32 operatorIndex) public {
        (uint256 operatorPK, address operator) = generateWallet(operatorIndex, "Operator");

        qstmeGems.helper_grantRole(OPERATOR_ROLE, operator);

        bytes32 digest = qstmeGems.composeNextUpdateUriAllowanceDigest(_tokenId, _newTokenUri);

        bytes memory signature = helper_sign(operatorPK, digest);
        string memory expectedFullUri = string.concat(baseUri, _newTokenUri);

        vm.expectEmit();
        emit IERC1155.URI(expectedFullUri, _tokenId);

        qstmeGems.setTokenURI(_tokenId, _newTokenUri, signature);

        vm.assertEq(toComparable(qstmeGems.uri(_tokenId)), toComparable(expectedFullUri));
    }

    function test_SetTokenUri_Revert_IfSignerIsNotAnOperator(uint256 _tokenId, string calldata _newTokenUri, uint32 anonymIndex) public {
        (uint256 anonymPK, address anonym) = generateWallet(anonymIndex, "Anonym");

        bytes32 digest = qstmeGems.composeNextUpdateUriAllowanceDigest(_tokenId, _newTokenUri);

        bytes memory signature = helper_sign(anonymPK, digest);

        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                anonym,
                OPERATOR_ROLE
            )
        );

        vm.prank(anonym);
        qstmeGems.setTokenURI(_tokenId, _newTokenUri, signature);

        vm.assertEq(toComparable(qstmeGems.uri(_tokenId)), toComparable(baseUri));
    }

    function test_SetBaseUri_Ok(address _operator, string calldata _newBaseUri, uint256 _tokenId, string calldata _tokenUri) public {
        vm.assume(bytes(_tokenUri).length > 0);
        vm.assume(_operator != address(0));

        qstmeGems.helper_grantRole(OPERATOR_ROLE, _operator);
        qstmeGems.exposed_setTokenURI(_tokenId, _tokenUri);

        vm.expectEmit();
        emit QstmeGems.BaseUriChanged(_newBaseUri);

        vm.prank(_operator);
        qstmeGems.setBaseURI(_newBaseUri);

        vm.assertEq(toComparable(qstmeGems.uri(_tokenId)), toComparable(string.concat(_newBaseUri, _tokenUri)));
    }

    function test_SetBaseUri_Revert_IfCallerIsNotAnOperator(address _anonym, string calldata _newBaseUri, uint256 _tokenId, string calldata _tokenUri) public {
        vm.assume(_anonym != address(0));
        vm.assume(!qstmeGems.hasRole(OPERATOR_ROLE, _anonym));

        qstmeGems.exposed_setTokenURI(_tokenId, _tokenUri);

        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                _anonym,
                OPERATOR_ROLE
            )
        );

        vm.prank(_anonym);
        qstmeGems.setBaseURI(_newBaseUri);

        vm.assertEq(toComparable(qstmeGems.uri(_tokenId)), toComparable(string.concat(baseUri, _tokenUri)));
    }

    function test_withdraw_Ok_ERC20asset(
        address _receiver,
        Asset memory _asset,
        uint32 _adminIndex
    ) public {
        assumeUnusedAddress(_receiver);
        assumeUnusedAddress(_asset.assetAddress);

        deployERC20(_asset.assetAddress);

        deal(_asset.assetAddress, address(qstmeGems), _asset.amount);
        (, address admin) = generateWallet(_adminIndex, "Admin");
        qstmeGems.helper_grantRole(DEFAULT_ADMIN_ROLE, admin);

        uint256 contractBalanceBefore = IERC20(_asset.assetAddress).balanceOf(address(qstmeGems));
        uint256 receiverBalanceBefore = IERC20(_asset.assetAddress).balanceOf(_receiver);

        vm.expectEmit();
        emit WithdrawingController.Withdrawn(_receiver, _asset.assetAddress, _asset.amount);

        vm.prank(admin);
        qstmeGems.withdraw(_receiver, _asset);

        uint256 contractBalanceAfter = IERC20(_asset.assetAddress).balanceOf(address(qstmeGems));
        uint256 receiverBalanceAfter = IERC20(_asset.assetAddress).balanceOf(_receiver);

        assertEq(contractBalanceAfter, contractBalanceBefore - _asset.amount);
        assertEq(receiverBalanceAfter, receiverBalanceBefore + _asset.amount);
    }

    function test_withdraw_Ok_NativeAsset(
        address _receiver,
        Asset memory _asset,
        uint32 _adminIndex
    ) public {
        vm.assume(_receiver != address(qstmeGems));
        assumePayable(_receiver);

        deal(address(qstmeGems), _asset.amount);
        (, address admin) = generateWallet(_adminIndex, "Admin");
        qstmeGems.helper_grantRole(DEFAULT_ADMIN_ROLE, admin);
        _asset.assetAddress = address(0);

        uint256 contractBalanceBefore = address(qstmeGems).balance;
        uint256 receiverBalanceBefore = address(_receiver).balance;

        vm.expectEmit();
        emit WithdrawingController.Withdrawn(_receiver, _asset.assetAddress, _asset.amount);

        vm.prank(admin);
        qstmeGems.withdraw(_receiver, _asset);

        uint256 contractBalanceAfter = address(qstmeGems).balance;
        uint256 receiverBalanceAfter = address(_receiver).balance;

        assertEq(contractBalanceAfter, contractBalanceBefore - _asset.amount);
        assertEq(receiverBalanceAfter, receiverBalanceBefore + _asset.amount);
    }

    function test_withdraw_RevertIf_NotAnAdmin(
        address _receiver,
        Asset memory _asset,
        uint32 _anonymIndex
    ) public {
        vm.assume(_receiver != address(qstmeGems));
        assumePayable(_receiver);

        deal(address(qstmeGems), _asset.amount);
        (, address anonym) = generateWallet(_anonymIndex, "Anonym");
        _asset.assetAddress = address(0);

        uint256 contractBalanceBefore = address(qstmeGems).balance;
        uint256 receiverBalanceBefore = address(_receiver).balance;

        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                anonym,
                DEFAULT_ADMIN_ROLE
            )
        );

        vm.prank(anonym);
        qstmeGems.withdraw(_receiver, _asset);

        uint256 contractBalanceAfter = address(qstmeGems).balance;
        uint256 receiverBalanceAfter = address(_receiver).balance;

        assertEq(contractBalanceAfter, contractBalanceBefore);
        assertEq(receiverBalanceAfter, receiverBalanceBefore);
    }

}
