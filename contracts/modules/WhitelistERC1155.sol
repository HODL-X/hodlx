// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "./WhitelistTicket.sol";
import "./ContractURI.sol";
import "../ERC2981/ERC2981ContractWideRoyalties.sol";
import "../opensea/ContextMixin.sol";

contract WhitelistERC1155 is ERC1155, ERC2981ContractWideRoyalties, Ownable, Pausable, ERC1155Burnable, ERC1155Supply, WhitelistTicket, ContextMixin, ContractURI {

    address private _openSeaProxyRegistryAddress;

    constructor(string memory uri_) ERC1155(uri_) {
        setOpenSeaProxyRegistryAddress(0x207Fa8Df3a17D96Ca7EA4f2893fcdCb78a304101);
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    // Pausable
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data) public onlyOwner {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    internal whenNotPaused override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC1155, ERC2981Base) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Opensea
    function setOpenSeaProxyRegistryAddress(address addr) public onlyOwner {
        _openSeaProxyRegistryAddress = addr;
    }

    // Override isApprovedForAll to auto-approve OS's proxy contract
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override view returns (bool isOperator) {
        // if OpenSea's ERC1155 Proxy Address is detected, auto-return true
        // for Polygon's Matic, use 0x207Fa8Df3a17D96Ca7EA4f2893fcdCb78a304101
        // for Polygon's Mumbai testnet, use 0x53d791f18155C211FF8b58671d0f7E9b50E596ad
        if (_operator == address(_openSeaProxyRegistryAddress)) {
            return true;
        }
        // otherwise, use the default ERC1155.isApprovedForAll()
        return ERC1155.isApprovedForAll(_owner, _operator);
    }

    // This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
    function _msgSender() internal virtual override view returns (address sender) {
        return ContextMixin.msgSender();
    }

    // Royalty
    /// @param recipient the royalties recipient
    /// @param value royalties value (between 0 and 10000)
    function setRoyalties(address recipient, uint256 value) public onlyOwner {
        _setRoyalties(recipient, value);
    }

    // ContractURL
    function setContractURI(string memory contractURI) public onlyOwner {
        _setContractURI(contractURI);
    }

    // Whitelist
    function addWhitelistTicket(address to, uint256 amount) public onlyOwner {
        _addWhitelistTicket(to, amount);
    }

    function addWhitelistTickets(address[] memory tos, uint256[] memory amounts) public onlyOwner {
        _addWhitelistTickets(tos, amounts);
    }

    function removeWhitelistTicket(address from, uint256 amount) public onlyOwner {
        _removeWhitelistTicket(from, amount);
    }

    function removeWhitelistTicketBatch(address[] memory froms, uint256[] memory amounts) public onlyOwner {
        _removeWhitelistTickets(froms, amounts);
    }

}