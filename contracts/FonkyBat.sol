// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

contract FonkyBat is ERC721Tradable {
    constructor(address _proxyRegistryAddress) ERC721Tradable("FonkyBats", "HRE", _proxyRegistryAddress) public {}

    function baseTokenURI() override public pure returns (string memory) {
        return "https://fonkybats.com/metadata-api/";
    }

    function contractURI() public pure returns (string memory) {
        return "127.0.0.1/contract/fonkybats";
    }
}
