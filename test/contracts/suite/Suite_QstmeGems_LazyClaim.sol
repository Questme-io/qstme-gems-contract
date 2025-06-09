// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {IAccessControl} from "@openzeppelin/5.3.0/access/IAccessControl.sol";
import {IERC1155} from "@openzeppelin/5.3.0/token/ERC1155/IERC1155.sol";

import "src/modules/WithdrawingController.sol";
import {QstmeGems} from "src/QstmeGems.sol";
import {Storage_QstmeGems} from "test/contracts/storage/Storage_QstmeGems.sol";

abstract contract Suite_QstmeGems_LazyClaim is Storage_QstmeGems {
    function test_LazyClaim_Ok(
        address _receiver,
        uint256 _tokenId,
        string calldata _newTokenUri,
        uint32 _minterIndex,
        uint32 _operatorIndex
    ) public {
        assumeUnusedAddress(_receiver);

        (uint256 minterPK, address minter) = generateWallet(_minterIndex, "Minter");
        (uint256 operatorPK, address operator) = generateWallet(_operatorIndex, "Operator");

        qstmeGems.helper_grantRole(MINTER_ROLE, minter);
        qstmeGems.helper_grantRole(OPERATOR_ROLE, operator);

        bytes32 digestClaim = qstmeGems.composeNextClaimAllowanceDigest(_receiver, _tokenId);
        bytes32 digestUpdateUri = qstmeGems.composeNextUpdateUriAllowanceDigest(_tokenId, _newTokenUri);

        bytes memory signatureClaim = helper_sign(minterPK, digestClaim);
        bytes memory signatureUpdateUri = helper_sign(operatorPK, digestUpdateUri);

        string memory expectedFullUri = string.concat(baseUri, _newTokenUri);
        uint256 balanceBefore = address(qstmeGems).balance;
        uint256 mintPrice = qstmeGems.mintPrice();

        vm.expectEmit();
        emit QstmeGems.GemMinted(_receiver, _tokenId);

        vm.expectEmit();
        emit IERC1155.URI(expectedFullUri, _tokenId);

        qstmeGems.lazyClaim{value: mintPrice}(_receiver, _tokenId, _newTokenUri, signatureClaim, signatureUpdateUri);

        vm.assertEq(qstmeGems.balanceOf(_receiver, _tokenId), 1);
        vm.assertEq(address(qstmeGems).balance, balanceBefore + qstmeGems.mintPrice());
        assertTrue(qstmeGems.mintControl(_receiver, _tokenId));
        vm.assertEq(toComparable(qstmeGems.uri(_tokenId)), toComparable(expectedFullUri));
    }

    function test_LazyClaim_Ok_IfCallingLazyMintConcurrently(
        address _receiver1,
        address _receiver2,
        uint256 _tokenId,
        string calldata _newTokenUri,
        uint32 _minterIndex,
        uint32 _operatorIndex
    ) public {
        assumeUnusedAddress(_receiver1);
        assumeUnusedAddress(_receiver2);
        vm.assume(_receiver1 != _receiver2);

        (uint256 minterPK, address minter) = generateWallet(_minterIndex, "Minter");
        (uint256 operatorPK, address operator) = generateWallet(_operatorIndex, "Operator");

        qstmeGems.helper_grantRole(MINTER_ROLE, minter);
        qstmeGems.helper_grantRole(OPERATOR_ROLE, operator);

        bytes32 digestClaim = qstmeGems.composeNextClaimAllowanceDigest(_receiver1, _tokenId);
        bytes32 digestUpdateUri = qstmeGems.composeNextUpdateUriAllowanceDigest(_tokenId, _newTokenUri);

        bytes memory signatureClaim = helper_sign(minterPK, digestClaim);
        bytes memory signatureUpdateUri = helper_sign(operatorPK, digestUpdateUri);

        string memory expectedFullUri = string.concat(baseUri, _newTokenUri);
        uint256 balanceBefore = address(qstmeGems).balance;
        uint256 mintPrice = qstmeGems.mintPrice();

        vm.expectEmit();
        emit QstmeGems.GemMinted(_receiver1, _tokenId);

        vm.expectEmit();
        emit IERC1155.URI(expectedFullUri, _tokenId);

        qstmeGems.lazyClaim{value: mintPrice}(_receiver1, _tokenId, _newTokenUri, signatureClaim, signatureUpdateUri);

        vm.assertEq(qstmeGems.balanceOf(_receiver1, _tokenId), 1);
        vm.assertEq(qstmeGems.balanceOf(_receiver2, _tokenId), 0);
        assertTrue(qstmeGems.mintControl(_receiver1, _tokenId));
        assertFalse(qstmeGems.mintControl(_receiver2, _tokenId));
        vm.assertEq(address(qstmeGems).balance, balanceBefore + qstmeGems.mintPrice());
        vm.assertEq(toComparable(qstmeGems.uri(_tokenId)), toComparable(expectedFullUri));

        // Second execution
        digestClaim = qstmeGems.composeNextClaimAllowanceDigest(_receiver2, _tokenId);

        signatureClaim = helper_sign(minterPK, digestClaim);

        vm.expectEmit();
        emit QstmeGems.GemMinted(_receiver2, _tokenId);

        qstmeGems.lazyClaim{value: mintPrice}(_receiver2, _tokenId, _newTokenUri, signatureClaim, signatureUpdateUri);

        vm.assertEq(qstmeGems.balanceOf(_receiver1, _tokenId), 1);
        vm.assertEq(qstmeGems.balanceOf(_receiver2, _tokenId), 1);
        assertTrue(qstmeGems.mintControl(_receiver1, _tokenId));
        assertTrue(qstmeGems.mintControl(_receiver2, _tokenId));
        vm.assertEq(address(qstmeGems).balance, balanceBefore + qstmeGems.mintPrice() * 2);
        vm.assertEq(toComparable(qstmeGems.uri(_tokenId)), toComparable(expectedFullUri));
    }

    function test_LazyClaim_Revert_IfMintingSameGemSecondTime(
        address _receiver,
        uint256 _tokenId,
        string calldata _newTokenUri,
        uint32 _minterIndex,
        uint32 _operatorIndex
    ) public {
        assumeUnusedAddress(_receiver);

        (uint256 minterPK, address minter) = generateWallet(_minterIndex, "Minter");
        (uint256 operatorPK, address operator) = generateWallet(_operatorIndex, "Operator");

        qstmeGems.helper_grantRole(MINTER_ROLE, minter);
        qstmeGems.helper_grantRole(OPERATOR_ROLE, operator);

        bytes32 digestClaim = qstmeGems.composeNextClaimAllowanceDigest(_receiver, _tokenId);
        bytes32 digestUpdateUri = qstmeGems.composeNextUpdateUriAllowanceDigest(_tokenId, _newTokenUri);

        bytes memory signatureClaim = helper_sign(minterPK, digestClaim);
        bytes memory signatureUpdateUri = helper_sign(operatorPK, digestUpdateUri);

        string memory expectedFullUri = string.concat(baseUri, _newTokenUri);
        uint256 balanceBefore = address(qstmeGems).balance;
        uint256 mintPrice = qstmeGems.mintPrice();

        vm.expectEmit();
        emit QstmeGems.GemMinted(_receiver, _tokenId);

        vm.expectEmit();
        emit IERC1155.URI(expectedFullUri, _tokenId);

        qstmeGems.lazyClaim{value: mintPrice}(_receiver, _tokenId, _newTokenUri, signatureClaim, signatureUpdateUri);

        vm.assertEq(qstmeGems.balanceOf(_receiver, _tokenId), 1);
        assertTrue(qstmeGems.mintControl(_receiver, _tokenId));
        vm.assertEq(address(qstmeGems).balance, balanceBefore + qstmeGems.mintPrice());
        vm.assertEq(toComparable(qstmeGems.uri(_tokenId)), toComparable(expectedFullUri));

        // Second execution
        digestClaim = qstmeGems.composeNextClaimAllowanceDigest(_receiver, _tokenId);

        signatureClaim = helper_sign(minterPK, digestClaim);

        vm.expectRevert(abi.encodeWithSelector(QstmeGems.AlreadyOwned.selector, _receiver, _tokenId));

        qstmeGems.lazyClaim{value: mintPrice}(_receiver, _tokenId, _newTokenUri, signatureClaim, signatureUpdateUri);

        vm.assertEq(qstmeGems.balanceOf(_receiver, _tokenId), 1);
        assertTrue(qstmeGems.mintControl(_receiver, _tokenId));
        vm.assertEq(address(qstmeGems).balance, balanceBefore + qstmeGems.mintPrice());
        vm.assertEq(toComparable(qstmeGems.uri(_tokenId)), toComparable(expectedFullUri));
    }

    function test_LazyClaim_Revert_IfMintSignerIsNotAMinter(
        address _receiver,
        uint256 _tokenId,
        string calldata _newTokenUri,
        uint32 _anonymIndex,
        uint32 _operatorIndex
    ) public {
        assumeUnusedAddress(_receiver);

        (uint256 anonymPK, address anonym) = generateWallet(_anonymIndex, "Anonym");
        (uint256 operatorPK, address operator) = generateWallet(_operatorIndex, "Operator");

        qstmeGems.helper_grantRole(OPERATOR_ROLE, operator);

        bytes32 digestClaim = qstmeGems.composeNextClaimAllowanceDigest(_receiver, _tokenId);
        bytes32 digestUpdateUri = qstmeGems.composeNextUpdateUriAllowanceDigest(_tokenId, _newTokenUri);

        bytes memory signatureClaim = helper_sign(anonymPK, digestClaim);
        bytes memory signatureUpdateUri = helper_sign(operatorPK, digestUpdateUri);

        uint256 balanceBefore = address(qstmeGems).balance;
        uint256 mintPrice = qstmeGems.mintPrice();

        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, anonym, MINTER_ROLE)
        );

        qstmeGems.lazyClaim{value: mintPrice}(_receiver, _tokenId, _newTokenUri, signatureClaim, signatureUpdateUri);

        vm.assertEq(qstmeGems.balanceOf(_receiver, _tokenId), 0);
        assertFalse(qstmeGems.mintControl(_receiver, _tokenId));
        vm.assertEq(address(qstmeGems).balance, balanceBefore);
        vm.assertEq(toComparable(qstmeGems.uri(_tokenId)), toComparable(baseUri));
    }

    function test_LazyClaim_Revert_IfMintDigestIsInvalid(
        address _receiver,
        address _receiverDigest,
        uint256 _tokenId,
        string calldata _newTokenUri,
        uint32 _minterIndex,
        uint32 _operatorIndex
    ) public {
        assumeUnusedAddress(_receiver);
        vm.assume(_receiver != _receiverDigest);

        (uint256 minterPK, address minter) = generateWallet(_minterIndex, "Minter");
        (uint256 operatorPK, address operator) = generateWallet(_operatorIndex, "Operator");

        qstmeGems.helper_grantRole(MINTER_ROLE, minter);
        qstmeGems.helper_grantRole(OPERATOR_ROLE, operator);

        bytes32 digestClaim = qstmeGems.composeNextClaimAllowanceDigest(_receiverDigest, _tokenId);
        bytes32 digestUpdateUri = qstmeGems.composeNextUpdateUriAllowanceDigest(_tokenId, _newTokenUri);

        bytes memory signatureClaim = helper_sign(minterPK, digestClaim);
        bytes memory signatureUpdateUri = helper_sign(operatorPK, digestUpdateUri);

        uint256 balanceBefore = address(qstmeGems).balance;
        uint256 mintPrice = qstmeGems.mintPrice();

        vm.expectPartialRevert(IAccessControl.AccessControlUnauthorizedAccount.selector);

        qstmeGems.lazyClaim{value: mintPrice}(_receiver, _tokenId, _newTokenUri, signatureClaim, signatureUpdateUri);

        vm.assertEq(qstmeGems.balanceOf(_receiver, _tokenId), 0);
        assertFalse(qstmeGems.mintControl(_receiver, _tokenId));
        vm.assertEq(address(qstmeGems).balance, balanceBefore);
        vm.assertEq(toComparable(qstmeGems.uri(_tokenId)), toComparable(baseUri));
    }

    function test_LazyClaim_Revert_IfUpdateUriSignerIsNotAnOperator(
        address _receiver,
        uint256 _tokenId,
        string calldata _newTokenUri,
        uint32 _minterIndex,
        uint32 _anonymIndex
    ) public {
        assumeUnusedAddress(_receiver);

        (uint256 minterPK, address minter) = generateWallet(_minterIndex, "Minter");
        (uint256 anonymPK, address anonym) = generateWallet(_anonymIndex, "Anonym");

        qstmeGems.helper_grantRole(MINTER_ROLE, minter);

        bytes32 digestClaim = qstmeGems.composeNextClaimAllowanceDigest(_receiver, _tokenId);
        bytes32 digestUpdateUri = qstmeGems.composeNextUpdateUriAllowanceDigest(_tokenId, _newTokenUri);

        bytes memory signatureClaim = helper_sign(minterPK, digestClaim);
        bytes memory signatureUpdateUri = helper_sign(anonymPK, digestUpdateUri);

        uint256 balanceBefore = address(qstmeGems).balance;
        uint256 mintPrice = qstmeGems.mintPrice();

        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, anonym, OPERATOR_ROLE)
        );

        qstmeGems.lazyClaim{value: mintPrice}(_receiver, _tokenId, _newTokenUri, signatureClaim, signatureUpdateUri);

        vm.assertEq(qstmeGems.balanceOf(_receiver, _tokenId), 0);
        assertFalse(qstmeGems.mintControl(_receiver, _tokenId));
        vm.assertEq(address(qstmeGems).balance, balanceBefore);
        vm.assertEq(toComparable(qstmeGems.uri(_tokenId)), toComparable(baseUri));
    }

    function test_LazyClaim_Revert_IfUpdateUriDigestIsInvalid(
        address _receiver,
        uint256 _tokenId,
        uint256 _tokenIdDigest,
        string calldata _newTokenUri,
        uint32 _minterIndex,
        uint32 _operatorIndex
    ) public {
        assumeUnusedAddress(_receiver);
        vm.assume(_tokenId != _tokenIdDigest);

        (uint256 minterPK, address minter) = generateWallet(_minterIndex, "Minter");
        (uint256 operatorPK, address operator) = generateWallet(_operatorIndex, "Operator");

        qstmeGems.helper_grantRole(MINTER_ROLE, minter);
        qstmeGems.helper_grantRole(OPERATOR_ROLE, operator);

        bytes32 digestClaim = qstmeGems.composeNextClaimAllowanceDigest(_receiver, _tokenId);
        bytes32 digestUpdateUri = qstmeGems.composeNextUpdateUriAllowanceDigest(_tokenIdDigest, _newTokenUri);

        bytes memory signatureClaim = helper_sign(minterPK, digestClaim);
        bytes memory signatureUpdateUri = helper_sign(operatorPK, digestUpdateUri);

        string memory expectedFullUri = string.concat(baseUri, _newTokenUri);
        uint256 balanceBefore = address(qstmeGems).balance;
        uint256 mintPrice = qstmeGems.mintPrice();

        vm.expectPartialRevert(IAccessControl.AccessControlUnauthorizedAccount.selector);

        qstmeGems.lazyClaim{value: mintPrice}(_receiver, _tokenId, _newTokenUri, signatureClaim, signatureUpdateUri);

        vm.assertEq(qstmeGems.balanceOf(_receiver, _tokenId), 0);
        assertFalse(qstmeGems.mintControl(_receiver, _tokenId));
        vm.assertEq(address(qstmeGems).balance, balanceBefore);
        vm.assertEq(toComparable(qstmeGems.uri(_tokenId)), toComparable(baseUri));
    }

    function test_LazyClaim_Revert_IfPaymentIsNotOk(
        uint256 _payment,
        address _receiver,
        uint256 _tokenId,
        string calldata _newTokenUri,
        uint32 _minterIndex,
        uint32 _operatorIndex
    ) public {
        assumeUnusedAddress(_receiver);
        vm.assume(_payment < qstmeGems.mintPrice());

        (uint256 minterPK, address minter) = generateWallet(_minterIndex, "Minter");
        (uint256 operatorPK, address operator) = generateWallet(_operatorIndex, "Operator");

        qstmeGems.helper_grantRole(MINTER_ROLE, minter);
        qstmeGems.helper_grantRole(OPERATOR_ROLE, operator);

        bytes32 digestClaim = qstmeGems.composeNextClaimAllowanceDigest(_receiver, _tokenId);
        bytes32 digestUpdateUri = qstmeGems.composeNextUpdateUriAllowanceDigest(_tokenId, _newTokenUri);

        bytes memory signatureClaim = helper_sign(minterPK, digestClaim);
        bytes memory signatureUpdateUri = helper_sign(operatorPK, digestUpdateUri);

        string memory expectedFullUri = string.concat(baseUri, _newTokenUri);
        uint256 balanceBefore = address(qstmeGems).balance;
        uint256 mintPrice = qstmeGems.mintPrice();

        vm.expectRevert(abi.encodeWithSelector(QstmeGems.NotEnoughPayment.selector, _payment, qstmeGems.mintPrice()));

        qstmeGems.lazyClaim{value: _payment}(_receiver, _tokenId, _newTokenUri, signatureClaim, signatureUpdateUri);

        vm.assertEq(qstmeGems.balanceOf(_receiver, _tokenId), 0);
        assertFalse(qstmeGems.mintControl(_receiver, _tokenId));
        vm.assertEq(address(qstmeGems).balance, balanceBefore);
        vm.assertEq(toComparable(qstmeGems.uri(_tokenId)), toComparable(baseUri));
    }
}
