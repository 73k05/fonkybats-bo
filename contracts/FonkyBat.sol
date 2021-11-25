// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

contract FonkyBat is ERC721Tradable {
    constructor(address _proxyRegistryAddress) ERC721Tradable("FonkyBats", "FBS", _proxyRegistryAddress) {
    }

    // All Fonky NFTs will be stored on IPFS it will never be possible to change this
    function baseTokenURI() override public pure returns (string memory) {
        return "ipfs://";
    }

    // Contract config (Used for market places) It is not related to NFTs that are all stored on IPFS Network
    function contractURI() public pure returns (string memory) {
        return "https://fonkybats.com/metadata-api/contract";
    }
}
