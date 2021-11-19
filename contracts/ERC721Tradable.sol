// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./common/meta-transactions/ContentMixin.sol";
import "./common/meta-transactions/NativeMetaTransaction.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title ERC721Tradable
 * ERC721Tradable - ERC721 contract that whitelists a trading address, and has minting functionality.
 */
abstract contract ERC721Tradable is ContextMixin, ERC721Enumerable, NativeMetaTransaction, Ownable {

    enum SaleState {Inactive, PreOrder, MainSale, End}

    SaleState public saleState;
    uint public preOrdersCount;

    //Total amount of NFTs minted
    uint private mintedNFTs;

    uint constant public MAX_NFT_SUPPLY = 9999;

    // Pre Order MAX config
    uint constant public PREORDERS_MAX_WALLET = 200;
    uint constant public PREORDERS_MAX_NFT = 500;
    uint constant public PREORDERS_MAX_NFT_PER_WALLET = 5;

    // Minting Payment Prices
    uint constant public PREORDERS_PRICE = 0.007 ether;
    uint constant public MAIN_SALE_PRICE = 0.009 ether;

    address proxyRegistryAddress;

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) ERC721(_name, _symbol) {
        proxyRegistryAddress = _proxyRegistryAddress;
        _initializeEIP712(_name);

        saleState = SaleState.Inactive;
        preOrdersCount = 0;
        mintedNFTs = 0;
    }

    /**
     * TinyPaw Version Set sale state
     * External OnlyOwner Access
     * Modify possibility to mint NFTs and their selling prices
     * @param _saleState one of Enum{Inactive, PreOrder, Sale}
     */
    function setSaleState(uint8 _saleState) external onlyOwner {
        //Once the sale is finished, there is no turning back NO MORE NFTs will ever be possible to be minted
        // This code is dangerous Owner should set End State with conscious
        // The State will be IMMUTABLE after End State has been set
//        if (saleState == End) {
//            return;
//        }
        saleState = SaleState(_saleState);
    }

    /**
     * FonkyBats AdMint
     * External OnlyOwner Access
     * @dev Mints a token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     * @param _numberOfTokens number of token to mint
     */
    function adMint(address _to, uint _numberOfTokens) external onlyOwner {
        require(_numberOfTokens > 0, "No such pre order plan: number of token should be > 0");
        mintNFTs(_to, _numberOfTokens);
    }

    /**
     * FonkyBats Pre Order Mint
     * External Public Access
     * Only available on Pre Sale
     * @param _to address of the future owner of the token
     * @param _numberOfTokens to get number of token to mint
     */
    function preOrder(address _to, uint _numberOfTokens) external payable {
        require(saleState == SaleState.PreOrder, "PreOrder is not allowed");
        require(preOrdersCount + _numberOfTokens < PREORDERS_MAX_NFT, "PreOrder ended or Max NFTs Minted");
        require(_numberOfTokens > 0, "No such pre order plan: number of token should be > 0");
        require(_numberOfTokens <= PREORDERS_MAX_NFT_PER_WALLET, string(abi.encodePacked("No such pre order plan: Too many tokens ordered: ", Strings.toString(_numberOfTokens), "<=", Strings.toString(PREORDERS_MAX_NFT_PER_WALLET), "?")));
        require(PREORDERS_PRICE * _numberOfTokens <= msg.value, "Incorrect ethers value ");

        preOrdersCount += 1;

        mintNFTs(_to, _numberOfTokens);
    }

    /**
     * FonkyBats Main Salr Mint
     * External Public Access
     * Only available on Main Sale
     * @param _to address of the future owner of the token
     * @param _numberOfTokens to get number of token to mint
     */
    function mainSaleMint(address _to, uint _numberOfTokens) external payable {
        require(saleState == SaleState.MainSale, "Main Sale is not allowed");
        require(_numberOfTokens > 0, "No such pre order plan: number of token should be > 0");
        require(MAIN_SALE_PRICE * _numberOfTokens <= msg.value, "Incorrect ethers value ");

        mintNFTs(_to, _numberOfTokens);
    }

    /**
     * FonkyBats Version AdMint
     * External OnlyOwner Access
     * Mint Batch tokens for multiple addresses
     * @param _accounts address of the future owner of the token
     * @param _amounts of token to mint
     */
    function sendTokens(address[] memory _accounts, uint[] memory _amounts) external onlyOwner {
        require(_accounts.length == _amounts.length, "accounts.length == amounts.length");
        for (uint i = 0; i < _accounts.length; i++) {
            mintNFTs(_accounts[i], _amounts[i]);
        }
    }

    /**
     * FonkyBats Version Mint
     * Internal Access
     * @param _to address of the future owner of the token
     * @param _amount of token to mint
     */
    function mintNFTs(address _to, uint _amount) internal maxSupplyCheck(_amount) {
        uint mintFrom = mintedNFTs + 1;
        mintedNFTs += _amount;
        for (uint i = 0; i < _amount; i++) {
            _mint(_to, mintFrom + i);
        }
    }

    /**
     * Check if we are not issuing more NFTs than it is possible to
     * @param _amount of NFTs to create
     */
    modifier maxSupplyCheck(uint _amount)  {
        require(mintedNFTs + _amount <= MAX_NFT_SUPPLY, "Tokens supply reached limit _o/");
        require(saleState != SaleState.End, "Sale is finished, no more NFTs can be minted, go to OpenSea and trade there");
        _;
    }

    function baseTokenURI() virtual public pure returns (string memory);

    function tokenURI(uint256 _tokenId) override public pure returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId)));
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
    override
    public
    view
    returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender()
    internal
    override
    view
    returns (address sender)
    {
        return ContextMixin.msgSender();
    }

    /**
     * Withdraw Money from the account
     */
    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        uint shareDev = balance * 2 / 100;
        uint shareMarket = balance * 8 / 100;
        // Dev royalties 2%
        payable(0xe83559a2e63c83039B1F849d12ebE81a40e17C23).transfer(shareDev);
        // Market royalties 8%
        payable(0xD10249d84e9a8E03bE192d580Eea8013E50890E6).transfer(shareMarket);
        // Creator royalties 90%
        payable(0x9Ad99955f6938367F4A703c60a957B639D250a95).transfer(balance - shareDev - shareMarket);
    }
}
