// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "./modules/WhitelistTicket.sol";
import "./modules/WhitelistERC1155.sol";
import "./modules/MintPausable.sol";
import "./modules/Blacklist.sol";

contract HodlXGallery is WhitelistERC1155, MintPausable, Blacklist {

    event OnlyWhitelistCanMintChanged(bool onlyWhitelistCanMint);
    event OnlyCorrectCodeCanMintChanged(bool onlyCorrectCodeCanMint);
    event MintMultiple(address indexed minter, uint256 tokenId, uint256 amount);

    uint256 private _maxTokenId = 1;
    uint256 private _maxTokens = 10000;
    uint256 private _maxTokensPerSale = 5;
    uint256 private _maxTokensPerWallet = 3;
    uint256 private _mintPrice = 1000000;
    bool private _onlyWhitelistCanMint = true;
    bool private _onlyAvailableTokenCanMint = true;
    uint256 private _mintAvailableToken = 1;

    constructor() WhitelistERC1155("https://meta.hodlx.club/projects/hodlx-gallery/metadata/{id}.json") {
        _setContractURI("https://meta.hodlx.club/projects/hodlx-gallery/metadata/project.json");
    }

    // Get & Set
    function setMaxTokenId(uint256 maxTokenId) public onlyOwner {
        _maxTokenId = maxTokenId;
    }

    function getMaxTokenId() public view returns (uint256) {
        return _maxTokenId;
    }

    function setMaxTokens(uint256 maxTokens) public onlyOwner {
        _maxTokens = maxTokens;
    }

    function getMaxTokens() public view returns (uint256) {
        return _maxTokens;
    }

    function setMaxTokensPerSale(uint256 maxTokensPerSale) public onlyOwner {
        _maxTokensPerSale = maxTokensPerSale;
    }

    function getMaxTokensPerSale() public view returns (uint256) {
        return _maxTokensPerSale;
    }

    function setMaxTokensPerWallet(uint256 maxTokensPerWallet) public onlyOwner {
        _maxTokensPerWallet = maxTokensPerWallet;
    }

    function getMaxTokensPerWallet() public view returns (uint256) {
        return _maxTokensPerWallet;
    }

    function setMintPrice(uint256 mintPrice) public onlyOwner {
        _mintPrice = mintPrice;
    }

    function getMintPrice() public view returns (uint256) {
        return _mintPrice;
    }

    function setOnlyWhitelistCanMint(bool onlyWhitelistCanMint) public onlyOwner {
        _onlyWhitelistCanMint = onlyWhitelistCanMint;
        emit OnlyWhitelistCanMintChanged(_onlyWhitelistCanMint);
    }

    function getOnlyWhitelistCanMint() public view returns (bool){
        return _onlyWhitelistCanMint;
    }

    function setOnlyAvailableTokenCanMint(bool onlyAvailableTokenCanMint) public onlyOwner {
        _onlyAvailableTokenCanMint = onlyAvailableTokenCanMint;
    }

    function getOnlyAvailableTokenCanMint() public view returns (bool){
        return _onlyAvailableTokenCanMint;
    }

    function setMintAvailableToken(uint256 mintAvailableToken) public onlyOwner {
        _mintAvailableToken = mintAvailableToken;
    }

    function getMintAvailableToken() public view returns (uint256){
        return _mintAvailableToken;
    }


    // Mint
    function mintMultipleTokens(uint256 tokenId, uint256 amount) public payable whenNotMintPaused {
        require(!isBlacklisted(_msgSender()), "'minter' address is a blacklisted address.");
        require(amount > 0 && amount <= _maxTokensPerSale, "Amount of tokens exceeds amount of tokens you can purchase in a single purchase.");
        require(amount > 0 && amount <= _maxTokensPerWallet, "Amount of tokens exceeds amount of tokens you can purchase in a wallet.");
        require(balanceOf(_msgSender(), tokenId) + amount <= _maxTokensPerWallet, "Amount of tokens exceeds amount of tokens you can purchase in a wallet.");
        require(msg.value >= _mintPrice * amount, "Amount of ETH sent not correct.");
        require(_maxTokens >= amount + totalSupply(tokenId), "Not enough tokens left to buy.");
        require(_maxTokenId >= tokenId, "You can't mint beyond Max Token Id");

        if (_onlyWhitelistCanMint) {
            require(isWhitelisted(_msgSender()), "'minter' address is not a whitelisted address");
            require(whitelistTicketOf(_msgSender()) >= amount, "'minter' must have a whitelist ticket");
            _removeWhitelistTicket(_msgSender(), amount);
        }

        if (_onlyAvailableTokenCanMint) {
            require(tokenId == _mintAvailableToken, "is not a mint available token");
        }

        _mint(_msgSender(), tokenId, amount, "");

        emit MintMultiple(_msgSender(), tokenId, amount);
    }

    function _msgSender() internal override(Context, WhitelistERC1155) view returns (address sender) {
        return ContextMixin.msgSender();
    }

    // MintPausable
    function mintPause() public onlyOwner {
        MintPausable._mintPause();
    }

    function mintUnpause() public onlyOwner {
        MintPausable._mintUnpause();
    }

    // Blacklist
    function addBlacklist(address account) public onlyOwner {
        _addBlacklist(account);
    }

    function addBlacklists(address[] memory accounts) public onlyOwner {
        _addBlacklists(accounts);
    }

    function removeBlacklist(address account) public onlyOwner {
        _removeBlacklist(account);
    }

    function removeBlacklists(address[] memory accounts) public onlyOwner {
        _removeBlacklists(accounts);
    }

    // Withdrawal
    function withdraw(address payable to) public onlyOwner {
        uint256 balance = address(this).balance;
        to.transfer(balance);
    }

    function withdraw(address payable to, uint256 amount) public onlyOwner {
        require(address(this).balance >= amount, "Address: insufficient balance");
        to.transfer(amount);
    }
}