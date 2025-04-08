// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/5.3.0/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/5.3.0/token/ERC20/utils/SafeERC20.sol";

/// @notice Combined data for asset address and its amount
/// @param asset - asset address
/// @param amount - amount of asset
/// @dev For native token asset should be zero address
struct Asset {
    address assetAddress;
    uint256 amount;
}

abstract contract WithdrawingController {
    using SafeERC20 for IERC20;

    event Withdrawn(address indexed receiver, address indexed asset, uint256 amount);

    /// @notice Withdraws asset from contract
    /// @param _receiver - Address where asset should be sent
    /// @param _asset - Asset that should be withdrawn
    function _withdraw(address payable _receiver, Asset memory _asset) internal {
        if (_asset.assetAddress == address(0)) {
            _sendNativeToken(_receiver, _asset.amount);
        } else {
            _sendERC20Token(_asset.assetAddress, _receiver, _asset.amount);
        }

        emit Withdrawn(_receiver, _asset.assetAddress, _asset.amount);
    }

    /// @notice Sends native token to specified address
    /// @param _receiver - Address where native token should be sent
    /// @param _amount - Amount of native token that should be sent
    function _sendNativeToken(address payable _receiver, uint256 _amount) internal {
        (bool sent,) = _receiver.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    /// @notice Sends ERC20 token to specified address
    /// @param _token - Address of ERC20 token
    /// @param _receiver - Address where ERC20 token should be sent
    /// @param _amount - Amount of ERC20 token that should be sent
    function _sendERC20Token(address _token, address _receiver, uint256 _amount) internal {
        IERC20(_token).safeTransfer(_receiver, _amount);
    }
}
