// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import './ERC2981/ERC2981ContractWideRoyalties.sol';
import './opensea/ContextMixin.sol';
import "./modules/MintPausable.sol";
import "./modules/TokenPausable.sol";
import "./modules/WhitelistTicket.sol";
import "./modules/Blacklist.sol";
import "./modules/ContractURI.sol";


contract HodlXSnkrs is ERC2981ContractWideRoyalties, ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable, ERC721Burnable, ContextMixin, MintPausable, TokenPausable, WhitelistTicket, Blacklist, ContractURI {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    event Mint(address indexed to, uint256 indexed tokenId, address indexed minter);
    event MintMultiple(address indexed to, uint256 indexed totalSupply, address indexed minter, uint256 amount);
    event Burn(address indexed to, uint256 indexed tokenId);
    event OnlyWhitelistCanMintChanged(bool onlyWhitelistCanMint);
    event OnlyCorrectCodeCanMintChanged(bool onlyCorrectCodeCanMint);

    string private _baseURIExtended;
    uint256 private _maxTokens = 500;
    uint256 private _maxTokensPerSale = 5;
    uint256 private _maxTokensPerWallet = 3;
    uint256 private _mintPrice = 1000000;
    bool private _onlyWhitelistCanMint = true;
    bool private _onlyCorrectCodeCanMint = false;
    address private _openSeaProxyRegistryAddress;
    uint256 private _randomNumber = 30;

    constructor (
        string memory baseURI,
        string memory initContractURI,
        string memory name,
        string memory symbol,
        address openSeaProxyRegistryAddress
    ) ERC721(name, symbol) {
        setBaseURI(baseURI);
        setContractURI(initContractURI);
        setOpenSeaProxyRegistryAddress(openSeaProxyRegistryAddress);
        setContractURI("https://meta.hodlx.club/projects/hodlx-snkrs/metadata/project.json");
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseURIExtended = baseURI;
    }

    function getBaseURI() public view returns (string memory) {
        return _baseURIExtended;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    // ContractURI
    function setContractURI(string memory contractURI) public onlyOwner {
        _setContractURI(contractURI);
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

    function setTokenURI(uint256 tokenId, string memory newTokenURI) public onlyOwner {
        ERC721URIStorage._setTokenURI(tokenId, newTokenURI);
    }

    function setRandomNumber(uint256 randomNumber) public onlyOwner {
        _randomNumber = randomNumber;
    }

    function setOpenSeaProxyRegistryAddress(address addr) public onlyOwner {
        _openSeaProxyRegistryAddress = addr;
    }

    function setOnlyWhitelistCanMint(bool onlyWhitelistCanMint) public onlyOwner {
        _onlyWhitelistCanMint = onlyWhitelistCanMint;
        emit OnlyWhitelistCanMintChanged(_onlyWhitelistCanMint);
    }

    function getOnlyWhitelistCanMint() public view returns (bool){
        return _onlyWhitelistCanMint;
    }

    function setOnlyCorrectCodeCanMint(bool onlyCorrectCodeCanMint) public onlyOwner {
        _onlyCorrectCodeCanMint = onlyCorrectCodeCanMint;
        emit OnlyCorrectCodeCanMintChanged(_onlyCorrectCodeCanMint);
    }

    function getOnlyCorrectCodeCanMint() public view returns (bool){
        return _onlyCorrectCodeCanMint;
    }

    // Pausable
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // MintPausable
    function mintPause() public onlyOwner {
        _mintPause();
    }

    function mintUnpause() public onlyOwner {
        _mintUnpause();
    }

    // TokenPausable
    function tokenPause(uint256 tokenId) public onlyOwner {
        _tokenPause(tokenId);
    }

    function tokenUnpause(uint256 tokenId) public onlyOwner {
        _tokenUnpause(tokenId);
    }

    function getCode(uint256 amount) internal view returns (string memory) {
        bytes4 code = bytes4(keccak256(abi.encodePacked(_msgSender(), _randomNumber, amount, balanceOf(_msgSender()))));
        return fromCode(code);
    }

    function toHexDigit(uint8 d) internal pure returns (bytes1) {
        if (0 <= d && d <= 9) {
            return bytes1(uint8(bytes1('0')) + d);
        } else if (10 <= uint8(d) && uint8(d) <= 15) {
            return bytes1(uint8(bytes1('a')) + d - 10);
        }
        revert();
    }

    function fromCode(bytes4 code) public pure returns (string memory) {
        bytes memory result = new bytes(10);
        result[0] = bytes1('0');
        result[1] = bytes1('x');
        for (uint i = 0; i < 4; ++i) {
            result[2 * i + 2] = toHexDigit(uint8(code[i]) / 16);
            result[2 * i + 3] = toHexDigit(uint8(code[i]) % 16);
        }
        return string(result);
    }

    function compareStrings(string memory a, string memory b) public pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    // Mint
    function safeMint(address to) internal {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _initTokenPause(tokenId);

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, Strings.toString(tokenId));

        emit Mint(to, tokenId, _msgSender());
    }

    function mintMultipleTokens(uint256 amount, string memory code) public payable whenNotMintPaused {
        require(!isBlacklisted(_msgSender()), "'minter' address is a blacklisted address.");
        require(amount > 0 && amount <= _maxTokensPerSale, "Amount of tokens exceeds amount of tokens you can purchase in a single purchase.");
        require(amount > 0 && amount <= _maxTokensPerWallet, "Amount of tokens exceeds amount of tokens you can purchase in a wallet.");
        require(balanceOf(_msgSender()) + amount <= _maxTokensPerWallet, "Amount of tokens exceeds amount of tokens you can purchase in a wallet.");
        require(msg.value >= _mintPrice * amount, "Amount of ETH sent not correct.");
        require(_maxTokens >= amount + ERC721Enumerable.totalSupply(), "Not enough tokens left to buy.");

        if (_onlyCorrectCodeCanMint) {
            require(compareStrings(getCode(amount), code), "Need the exact code.");
        }

        if (_onlyWhitelistCanMint) {
            require(isWhitelisted(_msgSender()), "'minter' address is not a whitelisted address");
            require(whitelistTicketOf(_msgSender()) >= amount, "'minter' must have a whitelist ticket");
            _removeWhitelistTicket(_msgSender(), amount);
        }

        for (uint256 i = 0; i < amount; i++) {
            safeMint(_msgSender());
        }

        if (_maxTokens == ERC721Enumerable.totalSupply()) {
            _mintPause();
        }

        emit MintMultiple(_msgSender(), ERC721Enumerable.totalSupply(), _msgSender(), amount);
    }

    // 하나씩 민팅하여 보내준다
    function mintToken(address to) public onlyOwner returns (bool) {
        safeMint(to);
        if (_maxTokens == ERC721Enumerable.totalSupply()) {
            mintPause();
        }
        return true;
    }

    function mintMultipleTokensByOwner(uint256 amount) public onlyOwner {
        require(_maxTokens >= amount + ERC721Enumerable.totalSupply(), "Not enough tokens left.");

        for (uint256 i = 0; i < amount; i++) {
            safeMint(_msgSender());
        }

        emit MintMultiple(_msgSender(), ERC721Enumerable.totalSupply(), _msgSender(), amount);
    }

    function tokensOfOwner(address owner) external view returns (uint256[] memory ownerTokens) {
        uint256 tokenCount = ERC721.balanceOf(owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        }
        uint256[] memory tokens = new uint256[](tokenCount);
        for (uint i = 0; i < tokenCount; i++) {
            tokens[i] = ERC721Enumerable.tokenOfOwnerByIndex(owner, i);
        }
        return tokens;
    }

    // Burn
    function burnToken(uint256 tokenId) public {
        ERC721Burnable.burn(tokenId);
        emit Burn(msg.sender, tokenId);
    }

    function burnTokenByOwner(uint256 tokenId) public onlyOwner {
        _burn(tokenId);
    }

    function transferToken(address to, uint256 tokenId) public {
        safeTransferFrom(msg.sender, to, tokenId);
    }

    function withdraw(address payable to) public onlyOwner {
        uint256 balance = address(this).balance;
        to.transfer(balance);
    }

    function withdraw(address payable to, uint256 amount) public onlyOwner {
        require(address(this).balance >= amount, "Address: insufficient balance");
        to.transfer(amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal
    whenNotPaused
    whenNotTokenPaused(tokenId)
    override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // Burn
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable, ERC2981Base) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Opensea
    /**
     * Override isApprovedForAll to auto-approve OS's proxy contract
    */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override(ERC721, IERC721) view returns (bool isOperator) {
        // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        // for Polygon's Matic mainnet, use 0x58807baD0B376efc12F5AD86aAc70E78ed67deaE
        // for Polygon's Mumbai testnet, use 0xff7Ca10aF37178BdD056628eF42fD7F799fAc77c
        if (_operator == address(_openSeaProxyRegistryAddress)) {
            return true;
        }
        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    }

    /**
    * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
    */
    function _msgSender() internal override view returns (address sender) {
        return ContextMixin.msgSender();
    }

    // Royalty
    function setRoyalties(address recipient, uint256 value) public onlyOwner {
        _setRoyalties(recipient, value);
    }

    // Whitelist
    function addWhitelistTicket(address account, uint256 amount) public onlyOwner {
        _addWhitelistTicket(account, amount);
    }

    function addWhitelistTickets(address[] memory accounts, uint256[] memory amounts) public onlyOwner {
        _addWhitelistTickets(accounts, amounts);
    }

    function removeWhitelistTicket(address account, uint256 amount) public onlyOwner {
        _removeWhitelistTicket(account, amount);
    }

    function removeWhitelistTickets(address[] memory accounts, uint256[] memory amounts) public onlyOwner {
        _removeWhitelistTickets(accounts, amounts);
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

    function balancesOf(address[] memory accounts) public view returns (uint256[] memory) {
        uint256[] memory batchBalances = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i]);
        }
        return batchBalances;
    }

    function ownersOf(uint256[] memory tokenIds) public view returns (address[] memory) {
        address[] memory owners = new address[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            owners[i] = ownerOf(tokenIds[i]);
        }
        return owners;
    }

}