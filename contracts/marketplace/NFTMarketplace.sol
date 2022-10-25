// contracts/NFTMarketplace.sol
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// adapt and edit from (Nader Dabit):
//    https://github.com/dabit3/polygon-ethereum-nextjs-marketplace/blob/main/contracts/Market.sol

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../ERC2981/ERC2981ContractWideRoyalties.sol";
import "./interfaces/INFTContract.sol";
import "./NFTCommon.sol";

contract NFTMarketplace is ReentrancyGuard, ERC2981ContractWideRoyalties, Ownable {
    using Address for address payable;
    using NFTCommon for INFTContract;
    using Counters for Counters.Counter;
    Counters.Counter private _itemCounter; //start from 1
    Counters.Counter private _itemSoldCounter;

    enum State {Created, Release, Deleted}

    string public constant REVERT_NOT_OWNER_OF_TOKEN_ID = "Marketplace::not an owner of token ID";
    string public constant REVERT_NOT_A_CREATOR = "Marketplace::not a creator of market item";
    string public constant REVERT_SELLER_NOT_OWNER = "Marketplace::seller creator not owner";
    string public constant REVERT_NFT_NOT_SENT = "Marketplace::NFT not sent";
    string public constant REVERT_INSUFFICIENT_VALUE = "Marketplace::Please submit the asking price";

    struct MarketItem {
        uint id;
        INFTContract nftContract;
        uint256 tokenId;
        address payable seller;
        address payable buyer;
        uint256 price;
        State state;
    }

    mapping(uint256 => MarketItem) private marketItems;

    event MarketItemCreated (
        uint indexed id,
        INFTContract indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address buyer,
        uint256 price,
        State state
    );

    event MarketItemSold (
        uint indexed id,
        INFTContract indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address buyer,
        uint256 price,
        State state
    );

    constructor() {
        _setRoyalties(msg.sender, 600);
    }

    /**
     * @dev create a MarketItem for NFT sale on the marketplace.
   * List an NFT.
   */
    function createMarketItem(
        INFTContract nftContract,
        uint256 tokenId,
        uint256 price
    ) public payable nonReentrant {

        require(
            nftContract.quantityOf(msg.sender, tokenId) > 0,
            REVERT_NOT_OWNER_OF_TOKEN_ID
        );

        require(price > 0, "Price must be at least 1 wei");
        //        require(msg.value == listingFee, "Fee must be equal to listing fee");

        _itemCounter.increment();
        uint256 id = _itemCounter.current();

        marketItems[id] = MarketItem(
            id,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            State.Created
        );

        // TODO
        //        require(IERC721(nftContract).getApproved(tokenId) == address(this), "NFT must be approved to market");
        // change to approve mechanism from the original direct transfer to market
        // IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        emit MarketItemCreated(
            id,
            nftContract,
            tokenId,
            msg.sender,
            address(0),
            price,
            State.Created
        );
    }

    /**
     * @dev delete a MarketItem from the marketplace.
   *
   * de-List an NFT.
   *
   * todo ERC721.approve can't work properly!! comment out
   */
    function deleteMarketItem(uint256 itemId) public nonReentrant {
        require(itemId <= _itemCounter.current(), "id must <= item count");
        require(marketItems[itemId].state == State.Created, "item must be on market");

        MarketItem storage item = marketItems[itemId];
        require(item.seller == msg.sender, REVERT_NOT_A_CREATOR);
        require(
            item.nftContract.quantityOf(msg.sender, item.tokenId) > 0,
            REVERT_NOT_OWNER_OF_TOKEN_ID
        );
        item.state = State.Deleted;

        emit MarketItemSold(
            itemId,
            item.nftContract,
            item.tokenId,
            item.seller,
            address(0),
            0,
            State.Deleted
        );

    }

    /**
     * @dev (buyer) buy a MarketItem from the marketplace.
   * Transfers ownership of the item, as well as funds
   * NFT:         seller    -> buyer
   * value:       buyer     -> seller
   * listingFee:  contract  -> marketOwner
   */
    function buyMarketItem(
        INFTContract nftContract,
        uint256 id
    ) public payable nonReentrant {

        MarketItem storage item = marketItems[id];
        //should use storge!!!!
        uint price = item.price;
        uint tokenId = item.tokenId;

        require(msg.value == price, REVERT_INSUFFICIENT_VALUE);
        //        require(IERC721(nftContract).getApproved(tokenId) == address(this), "NFT must be approved to market");

        require(
            item.nftContract.quantityOf(item.seller, tokenId) > 0,
            REVERT_SELLER_NOT_OWNER
        );

        item.buyer = payable(msg.sender);
        item.state = State.Release;
        _itemSoldCounter.increment();

        bool success = item.nftContract.safeTransferFrom_(
            item.seller,
            msg.sender,
            tokenId,
            new bytes(0)
        );
        require(success, REVERT_NFT_NOT_SENT);

        //        IERC721(nftContract).transferFrom(item.seller, msg.sender, tokenId);
        //        payable(marketOwner).transfer(listingFee);
        //        _takeFee(totalPrice);
        uint256 royaltyAmount = _takeRoyalty(item.price);
        uint256 sendPrice = msg.value - royaltyAmount;
        payable(_royaltyReceiver()).transfer(royaltyAmount);
        item.seller.transfer(sendPrice);

        emit MarketItemSold(
            id,
            nftContract,
            tokenId,
            item.seller,
            msg.sender,
            price,
            State.Release
        );
    }

    /**
     * @dev Returns all unsold market items
   * condition:
   *  1) state == Created
   *  2) buyer = 0x0
   *  3) still have approve
   */

    function fetchAllItems() public view returns (MarketItem[] memory) {
        return fetchHelper(FetchOperator.AllItems);
    }

    function fetchAllItemsByContractAddress(INFTContract contractAddress) public view returns (MarketItem[] memory) {
        return fetchHelperByContractAddress(FetchOperator.AllItems, contractAddress);
    }

    function fetchAllActiveItems() public view returns (MarketItem[] memory) {
        return fetchHelper(FetchOperator.AllActiveItems);
    }

    function fetchAllActiveItemsByContractAddress(INFTContract contractAddress) public view returns (MarketItem[] memory) {
        return fetchHelperByContractAddress(FetchOperator.AllActiveItems, contractAddress);
    }

    function fetchAllDeletedItems() public view returns (MarketItem[] memory) {
        return fetchHelper(FetchOperator.AllDeletedItems);
    }

    function fetchAllDeletedItemsByContractAddress(INFTContract contractAddress) public view returns (MarketItem[] memory) {
        return fetchHelperByContractAddress(FetchOperator.AllDeletedItems, contractAddress);
    }

    /**
     * @dev Returns only market items a user has purchased
   * todo pagination
   */
    function fetchMyPurchasedItems() public view returns (MarketItem[] memory) {
        return fetchHelper(FetchOperator.MyPurchasedItems);
    }

    function fetchMyPurchasedItemsByContractAddress(INFTContract contractAddress) public view returns (MarketItem[] memory) {
        return fetchHelperByContractAddress(FetchOperator.MyPurchasedItems, contractAddress);
    }

    function fetchMySoldItems() public view returns (MarketItem[] memory) {
        return fetchHelper(FetchOperator.MySoldItems);
    }

    function fetchMySoldItemsByContractAddress(INFTContract contractAddress) public view returns (MarketItem[] memory) {
        return fetchHelperByContractAddress(FetchOperator.MySoldItems, contractAddress);
    }

    function fetchMyCreatedItems() public view returns (MarketItem[] memory) {
        return fetchHelper(FetchOperator.MyCreatedItems);
    }

    function fetchMyCreatedItemsByContractAddress(INFTContract contractAddress) public view returns (MarketItem[] memory) {
        return fetchHelperByContractAddress(FetchOperator.MyCreatedItems, contractAddress);
    }

    function fetchMyActiveItems() public view returns (MarketItem[] memory) {
        return fetchHelper(FetchOperator.MyActiveItems);
    }

    function fetchMyActiveItemsByContractAddress(INFTContract contractAddress) public view returns (MarketItem[] memory) {
        return fetchHelperByContractAddress(FetchOperator.MyActiveItems, contractAddress);
    }

    function fetchMyDeletedItems() public view returns (MarketItem[] memory) {
        return fetchHelper(FetchOperator.MyDeletedItems);
    }

    function fetchMyDeletedItemsByContractAddress(INFTContract contractAddress) public view returns (MarketItem[] memory) {
        return fetchHelperByContractAddress(FetchOperator.MyDeletedItems, contractAddress);
    }

    enum FetchOperator {
        MyActiveItems,
        MyDeletedItems,
        MyPurchasedItems,
        MySoldItems,
        MyCreatedItems,
        AllItems,
        AllActiveItems,
        AllDeletedItems
    }

    /**
     * @dev fetch helper
     * todo pagination
    */
    function fetchHelper(FetchOperator _op) private view returns (MarketItem[] memory) {
        uint total = _itemCounter.current();

        uint itemCount = 0;
        for (uint i = 1; i <= total; i++) {
            if (isCondition(marketItems[i], _op)) {
                itemCount ++;
            }
        }

        uint index = 0;
        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint i = 1; i <= total; i++) {
            if (isCondition(marketItems[i], _op)) {
                items[index] = marketItems[i];
                index ++;
            }
        }
        return items;
    }

    function fetchHelperByContractAddress(FetchOperator _op, INFTContract contractAddress) private view returns (MarketItem[] memory) {
        uint total = _itemCounter.current();

        uint itemCount = 0;
        for (uint i = 1; i <= total; i++) {
            if (isCondition(marketItems[i], _op) && marketItems[i].nftContract == contractAddress) {
                itemCount ++;
            }
        }

        uint index = 0;
        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint i = 1; i <= total; i++) {
            if (isCondition(marketItems[i], _op) && marketItems[i].nftContract == contractAddress) {
                items[index] = marketItems[i];
                index ++;
            }
        }
        return items;
    }
    /**
     * @dev helper to build condition
   *
   * todo should reduce duplicate contract call here
   * (IERC721(item.nftContract).getApproved(item.tokenId) called in two loop
   */
    function isCondition(MarketItem memory item, FetchOperator _op) private view returns (bool){
        if (_op == FetchOperator.MyCreatedItems) {
            return item.seller == msg.sender && item.state != State.Deleted;
        } else if (_op == FetchOperator.MyPurchasedItems) {
            return item.buyer == msg.sender;
        } else if (_op == FetchOperator.MySoldItems) {
            return item.seller == msg.sender && item.state == State.Release;
        } else if (_op == FetchOperator.MyActiveItems) {
            return item.seller == msg.sender && item.state == State.Created;
        } else if (_op == FetchOperator.MyDeletedItems) {
            return item.seller == msg.sender && item.state == State.Deleted;
        } else if (_op == FetchOperator.AllItems) {
            return true;
        } else if (_op == FetchOperator.AllActiveItems) {
            return item.state == State.Created;
        } else if (_op == FetchOperator.AllDeletedItems) {
            return item.state == State.Deleted;
        } else {
            return false;
        }
    }


    // Royalty
    function setRoyalties(address recipient, uint256 value) public onlyOwner {
        _setRoyalties(recipient, value);
    }

    function _takeRoyalty(uint256 totalPrice) internal view returns (uint256) {
        address receiver;
        uint256 royaltyAmount;
        (receiver, royaltyAmount) = super.royaltyInfo(0, totalPrice);
        return royaltyAmount;
    }

    function _royaltyReceiver() internal view returns (address) {
        address receiver;
        uint256 royaltyAmount;
        (receiver, royaltyAmount) = super.royaltyInfo(0, 0);
        return receiver;
    }

    // MarketItem
    function setMarketItemState(uint256 itemId, State state) public onlyOwner {
        require(itemId <= _itemCounter.current(), "id must <= item count");
        marketItems[itemId].state = state;
    }
}