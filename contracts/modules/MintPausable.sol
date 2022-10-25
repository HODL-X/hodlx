// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract MintPausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event MintPaused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event MintUnpaused(address account);

    bool private _mintPaused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _mintPaused = true;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function mintPaused() public view virtual returns (bool) {
        return _mintPaused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotMintPaused() {
        require(!mintPaused(), "MintPausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenMintPaused() {
        require(mintPaused(), "MintPausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _mintPause() internal virtual whenNotMintPaused {
        _mintPaused = true;
        emit MintPaused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _mintUnpause() internal virtual whenMintPaused {
        _mintPaused = false;
        emit MintUnpaused(_msgSender());
    }
}
