// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.3.0-rc.0) (token/ERC20/extensions/draft-ERC20TemporaryApproval.sol)

pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Upgradeable} from "../ERC20Upgradeable.sol";
import {IERC7674} from "@openzeppelin/contracts/interfaces/draft-IERC7674.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SlotDerivation} from "@openzeppelin/contracts/utils/SlotDerivation.sol";
import {TransientSlot} from "@openzeppelin/contracts/utils/TransientSlot.sol";
import {Initializable} from "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {ERC20} that adds support for temporary allowances following ERC-7674.
 *
 * WARNING: This is a draft contract. The corresponding ERC is still subject to changes.
 *
 * _Available since v5.1._
 */
abstract contract ERC20TemporaryApprovalUpgradeable is Initializable, ERC20Upgradeable, IERC7674 {
    using SlotDerivation for bytes32;
    using TransientSlot for bytes32;
    using TransientSlot for TransientSlot.Uint256Slot;

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.ERC20_TEMPORARY_APPROVAL_STORAGE")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant ERC20_TEMPORARY_APPROVAL_STORAGE =
        0xea2d0e77a01400d0111492b1321103eed560d8fe44b9a7c2410407714583c400;

    function __ERC20TemporaryApproval_init() internal onlyInitializing {
    }

    function __ERC20TemporaryApproval_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev {allowance} override that includes the temporary allowance when looking up the current allowance. If
     * adding up the persistent and the temporary allowances result in an overflow, type(uint256).max is returned.
     */
    function allowance(address owner, address spender) public view virtual override(IERC20, ERC20Upgradeable) returns (uint256) {
        (bool success, uint256 amount) = Math.tryAdd(
            super.allowance(owner, spender),
            _temporaryAllowance(owner, spender)
        );
        return success ? amount : type(uint256).max;
    }

    /**
     * @dev Internal getter for the current temporary allowance that `spender` has over `owner` tokens.
     */
    function _temporaryAllowance(address owner, address spender) internal view virtual returns (uint256) {
        return _temporaryAllowanceSlot(owner, spender).tload();
    }

    /**
     * @dev Alternative to {approve} that sets a `value` amount of tokens as the temporary allowance of `spender` over
     * the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Requirements:
     * - `spender` cannot be the zero address.
     *
     * Does NOT emit an {Approval} event.
     */
    function temporaryApprove(address spender, uint256 value) public virtual returns (bool) {
        _temporaryApprove(_msgSender(), spender, value);
        return true;
    }

    /**
     * @dev Sets `value` as the temporary allowance of `spender` over the `owner`'s tokens.
     *
     * This internal function is equivalent to `temporaryApprove`, and can be used to e.g. set automatic allowances
     * for certain subsystems, etc.
     *
     * Requirements:
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     *
     * Does NOT emit an {Approval} event.
     */
    function _temporaryApprove(address owner, address spender, uint256 value) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _temporaryAllowanceSlot(owner, spender).tstore(value);
    }

    /**
     * @dev {_spendAllowance} override that consumes the temporary allowance (if any) before eventually falling back
     * to consuming the persistent allowance.
     * NOTE: This function skips calling `super._spendAllowance` if the temporary allowance
     * is enough to cover the spending.
     */
    function _spendAllowance(address owner, address spender, uint256 value) internal virtual override {
        // load transient allowance
        uint256 currentTemporaryAllowance = _temporaryAllowance(owner, spender);

        // Check and update (if needed) the temporary allowance + set remaining value
        if (currentTemporaryAllowance > 0) {
            // All value is covered by the infinite allowance. nothing left to spend, we can return early
            if (currentTemporaryAllowance == type(uint256).max) {
                return;
            }
            // check how much of the value is covered by the transient allowance
            uint256 spendTemporaryAllowance = Math.min(currentTemporaryAllowance, value);
            unchecked {
                // decrease transient allowance accordingly
                _temporaryApprove(owner, spender, currentTemporaryAllowance - spendTemporaryAllowance);
                // update value necessary
                value -= spendTemporaryAllowance;
            }
        }
        // reduce any remaining value from the persistent allowance
        if (value > 0) {
            super._spendAllowance(owner, spender, value);
        }
    }

    function _temporaryAllowanceSlot(address owner, address spender) private pure returns (TransientSlot.Uint256Slot) {
        return ERC20_TEMPORARY_APPROVAL_STORAGE.deriveMapping(owner).deriveMapping(spender).asUint256();
    }
}
