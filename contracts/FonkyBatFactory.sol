// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IFactoryERC721.sol";
import "./FonkyBat.sol";

// Factory contracts for running gas-free presales of items that haven't been minted yet.
contract FonkyBatFactory is FactoryERC721, Ownable {
    using Strings for string;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    address public proxyRegistryAddress;
    address public nftAddress;
    address public lootBoxNftAddress;
    string public baseURI = "https://fonkybats.com/metadata-api/factory/";

    /*
     * Enforce the existence of only 10 000 FonkyBats.
     */
    uint256 FONKYBAT_SUPPLY = 10000;

    constructor(address _proxyRegistryAddress, address _nftAddress) {
        proxyRegistryAddress = _proxyRegistryAddress;
        nftAddress = _nftAddress;

        fireTransferEvents(address(0), owner());
    }

    function name() override external pure returns (string memory) {
        return "Fonkybat Item Sale";
    }

    function symbol() override external pure returns (string memory) {
        return "CPF";
    }

    function supportsFactoryInterface() override public pure returns (bool) {
        return true;
    }

    function transferOwnership(address newOwner) override public onlyOwner {
        address _prevOwner = owner();
        super.transferOwnership(newOwner);
        fireTransferEvents(_prevOwner, newOwner);
    }

    function fireTransferEvents(address _from, address _to) private {
        emit Transfer(_from, _to, 0);
    }

    /**
     * Mint NFTs for presale
     */
    function mint(uint256 _numberFonkyBatsToMint, address _toAddress) override public {
        // Must be sent from the owner proxy or owner.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        assert(
            address(proxyRegistry.proxies(owner())) == _msgSender() ||
            owner() == _msgSender()
        );
        require(canMint(_numberFonkyBatsToMint));

        FonkyBat nftFonkyBat = FonkyBat(nftAddress);
        for (uint256 i = 0; i < _numberFonkyBatsToMint; i++) {
            nftFonkyBat.mintTo(_toAddress);
        }
    }

    /**
     * Has enough supply to mint number of nfts
     */
    function canMint(uint256 _numberFonkyBatsToMint) override public view returns (bool) {
        if (_numberFonkyBatsToMint >= FONKYBAT_SUPPLY || _numberFonkyBatsToMint <= 0) {
            return false;
        }

        FonkyBat openSeaFonkyBat = FonkyBat(nftAddress);
        uint256 fonkyBatSupply = openSeaFonkyBat.totalSupply();

        return fonkyBatSupply < (FONKYBAT_SUPPLY - _numberFonkyBatsToMint);
    }


    function tokenURI(uint256 _optionId) override external view returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(_optionId)));
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use transferFrom so the frontend doesn't have to worry about different method names.
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        mint(_tokenId, _to);
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use isApprovedForAll so the frontend doesn't have to worry about different method names.
     */
    function isApprovedForAll(address _owner, address _operator)
    public
    view
    returns (bool)
    {
        if (owner() == _owner && _owner == _operator) {
            return true;
        }

        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (
            owner() == _owner &&
            address(proxyRegistry.proxies(_owner)) == _operator
        ) {
            return true;
        }

        return false;
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use isApprovedForAll so the frontend doesn't have to worry about different method names.
     */
    function ownerOf(uint256 _tokenId) public view returns (address _owner) {
        return owner();
    }
}
