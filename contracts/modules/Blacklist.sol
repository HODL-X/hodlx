// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Blacklist is Ownable {

    mapping(address => bool) _blacklist;

    event BlacklistAdded(address indexed account);
    event BlacklistRemoved(address indexed account);

    modifier onlyBlacklisted() {
        require(isBlacklisted(msg.sender));
        _;
    }

    function isBlacklisted(address account) public view returns (bool) {
        return _blacklist[account];
    }

    function _addBlacklist(address account) internal virtual {
        _blacklist[account] = true;
        emit BlacklistAdded(account);
    }

    function _addBlacklists(address[] memory accounts) internal virtual {
        for (uint256 i = 0; i < accounts.length; ++i) {
            _blacklist[accounts[i]] = true;
        }
    }

    function _removeBlacklist(address account) internal virtual {
        _blacklist[account] = false;
        emit BlacklistRemoved(account);
    }

    function _removeBlacklists(address[] memory accounts) internal virtual {
        for (uint256 i = 0; i < accounts.length; ++i) {
            _blacklist[accounts[i]] = false;
        }
    }


}