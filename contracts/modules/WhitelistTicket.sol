// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract WhitelistTicket is Context {
    using Address for address;

    mapping(address => uint256) private _whitelists;

    event WhitelistTicketAdded(address operator, address to, uint256 amount);
    event WhitelistTicketsAdded(address operator, address[] tos, uint256[] amounts);
    event WhitelistTicketRemoved(address operator, address from, uint256 amount);
    event WhitelistTicketsRemoved(address operator, address[] froms, uint256[] amounts);

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender));
        _;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return whitelistTicketOf(account) > 0;
    }

    function whitelistTicketOf(address account) public view returns (uint256) {
        require(account != address(0), "WhitelistMint: whitelist ticket query for the zero address");
        return _whitelists[account];
    }

    function whitelistTicketsOf(address[] memory accounts) public view returns (uint256[] memory) {
        uint256[] memory batchTickets = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; ++i) {
            batchTickets[i] = whitelistTicketOf(accounts[i]);
        }
        return batchTickets;
    }

    function _addWhitelistTicket(address to, uint256 amount) internal virtual {
        require(to != address(0), "WhitelistMint: add whitelist to the zero address");

        address operator = _msgSender();
        _whitelists[to] += amount;
        emit WhitelistTicketAdded(operator, to, amount);
    }

    function _addWhitelistTickets(address[] memory tos, uint256[] memory amounts) internal virtual {
        require(tos.length == amounts.length, "WhitelistMint: tos and amounts length mismatch");

        for (uint256 i = 0; i < tos.length; i++) {
            _whitelists[tos[i]] += amounts[i];
        }

        address operator = _msgSender();
        emit WhitelistTicketsAdded(operator, tos, amounts);
    }

    function _removeWhitelistTicket(address from, uint256 amount) internal virtual {
        require(from != address(0), "WhitelistMint: remove from the zero address");

        uint256 fromTicket = _whitelists[from];
        require(fromTicket >= amount, "WhitelistMint: remove amount exceeds balance");
    unchecked {
        _whitelists[from] = fromTicket - amount;
    }

        address operator = _msgSender();
        emit WhitelistTicketRemoved(operator, from, amount);
    }

    function _removeWhitelistTickets(address[] memory froms, uint256[] memory amounts) internal virtual {
        require(froms.length == amounts.length, "WhitelistMint: froms and amounts length mismatch");

        for (uint256 i = 0; i < froms.length; i++) {
            address from = froms[i];
            uint256 amount = amounts[i];

            uint256 fromTicket = _whitelists[from];
            require(fromTicket >= amount, "WhitelistMint: remove amount exceeds tickets");
        unchecked {
            _whitelists[from] = fromTicket - amount;
        }
        }

        address operator = _msgSender();
        emit WhitelistTicketsRemoved(operator, froms, amounts);
    }

}