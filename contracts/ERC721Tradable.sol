// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
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

    enum SaleState {Inactive, PreOrder, Sale}
    struct PreOrderPlan {
        uint price;
        uint amount;
    }

    SaleState public saleState;
    uint public preOrdersCount;

    uint constant public TOKEN_ID = 0;
    uint constant public MAX_PREORDERS = 200;

    using SafeMath for uint256;

    address proxyRegistryAddress;
    uint256 private _currentTokenId = 0;

    mapping(uint => PreOrderPlan) public preOrderPlans;

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) ERC721(_name, _symbol) {
        proxyRegistryAddress = _proxyRegistryAddress;
        _initializeEIP712(_name);

        preOrderPlans[1] = PreOrderPlan(0.04 ether, 1);
        preOrderPlans[2] = PreOrderPlan(0.07 ether, 2);
        preOrderPlans[3] = PreOrderPlan(0.1 ether, 3);

        saleState = SaleState.Inactive;
        mintPrice = 0.06 ether;
        maxSupply = 5000;
    }

    function setSaleState(SaleState _saleState) external onlyOwner {
        saleState = _saleState;
    }

    /**
     * OpenSea Version Mint
     * External OnlyOwner Access
     * @dev Mints a token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     */
    function mintTo(address _to) external onlyOwner {
        uint256 newTokenId = _getNextTokenId();
        _mint(_to, newTokenId);
        _incrementTokenId();
    }

    /**
     * TinyPaw Version Mint
     * External Public Access
     * Only available on Pre Sale
     * @param _to address of the future owner of the token
     * @param _amount of token to mint
     */
    function preOrder(address _to, uint plan) external payable {
        require(saleState == SaleState.PreOrder, "PreOrder is not allowed");
        require(preOrdersCount < MAX_PREORDERS, "PreOrder ended");
        require(preOrderPlans[plan].amount != 0, "No such pre order plan");
        require(preOrderPlans[plan].price == msg.value, "Incorrect ethers value");

        preOrdersCount += 1;
        mintTokens(_to, preOrderPlans[plan].amount);
    }

    /**
     * TinyPaw Version Mint
     * External OnlyOwner Access
     * Mint Batch tokens for multiple addresses
     * @param _accounts address of the future owner of the token
     * @param _amounts of token to mint
     */
    function sendTokens(address[] memory _accounts, uint[] memory _amounts) external onlyOwner {
        require(_accounts.length == _amounts.length, "accounts.length == amounts.length");
        for (uint i = 0; i < _accounts.length; i++) {
            mintTokens(_accounts[i], _amounts[i]);
        }
    }

    /**
     * TinyPaw Version Mint
     * Internal Access
     * @param _to address of the future owner of the token
     * @amount _amount of token to mint
     */
    function mintTokens(address account, uint amount) internal maxSupplyCheck(amount) {
        tokensSupply += amount;
        _mint(account, TOKEN_ID, amount, "");
    }

    /**
     * TinyPaw Version Mint
     * Internal Access
     * @param _to address of the future owner of the token
     * @amount _amount of token to mint
     */
    function mintNFTs(address account, uint amount) internal maxSupplyCheck(amount) {
        uint mintFrom = mintedNFTs + 1;
        mintedNFTs += amount;
        for (uint i = 0; i < amount; i++) {
            _mint(account, mintFrom + i, 1, "");
        }
    }

    /**
     * TinyPaw Version Mint
     * External Public Access
     * Only available on Main Sale
     * @param _to address of the future owner of the token
     * @amount _amount of token to mint
     */
    function mint(uint _amount) external payable {
        require(saleState == SaleState.Sale, "Minting is not allowed");
        require(mintPrice * amount == msg.value, "Incorrect ethers value");
        mintNFTs(msg.sender, amount);
    }

    /**
     * @dev calculates the next token ID based on value of _currentTokenId
     * @return uint256 for the next token ID
     */
    function _getNextTokenId() private view returns (uint256) {
        return _currentTokenId.add(1);
    }

    /**
     * @dev increments the value of _currentTokenId
     */
    function _incrementTokenId() private {
        _currentTokenId++;
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
        uint share1 = balance * 1 / 100;
        // Dev royalties 1%
        payable(0x574B5DE3E79Aa7f701E104Dc7aE36cf644770E5f).transfer(share1);
        // Creator royalties 99%
        payable(0x9Ad99955f6938367F4A703c60a957B639D250a95).transfer(balance - share1);
    }
}
