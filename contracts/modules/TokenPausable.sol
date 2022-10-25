// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";


abstract contract TokenPausable is Context {

    mapping(uint256 => bool) private _tokenPaused;

    /**
     * @dev Emitted when the token pause is triggered by `account`.
     */
    event TokenPaused(address account, uint256 tokenId);

    /**
     * @dev Emitted when the token pause is lifted by `account`.
     */
    event TokenUnpaused(address account, uint256 tokenId);

    /**
     * @dev Initializes the contract in token unpaused state.
     */
    constructor() {

    }

    function _initTokenPause(uint256 tokenId) internal {
        _tokenPaused[tokenId] = false;
    }


    /**
     * @dev Returns true if the token is paused, and false otherwise.
     */
    function tokenPaused(uint256 tokenId) public view virtual returns (bool) {
        return _tokenPaused[tokenId];
    }

    /**
     * @dev Modifier to make a function callable only when the token is not paused.
     *
     * Requirements:
     *
     * - The token must not be paused.
     */
    modifier whenNotTokenPaused(uint256 tokenId) {
        require(!tokenPaused(tokenId), "TokenPausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the token is paused.
     *
     * Requirements:
     *
     * - The token must be paused.
     */
    modifier whenTokenPaused(uint256 tokenId) {
        require(tokenPaused(tokenId), "TokenPausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The token must not be paused.
     */
    function _tokenPause(uint256 tokenId) internal virtual whenNotTokenPaused(tokenId) {
        _tokenPaused[tokenId] = true;
        emit TokenPaused(_msgSender(), tokenId);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The token must be paused.
     */
    function _tokenUnpause(uint256 tokenId) internal virtual whenTokenPaused(tokenId) {
        _tokenPaused[tokenId] = false;
        emit TokenUnpaused(_msgSender(), tokenId);
    }
}
