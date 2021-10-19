// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Fonkybat is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("fonkybat", "HRE") {}

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    
    interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
    function _baseURI() internal pure override returns (string memory) {
        return "http://";
    }
    function setMintPrice(uint _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setSaleState(SaleState _saleState) external onlyOwner {
        saleState = _saleState;
    }

    function setMaxNFTPerMint(uint _maxNFTPerMint) external onlyOwner {
        maxNFTPerMint = _maxNFTPerMint;
    }

    function setMaxSupply(uint _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }
     function configure(uint _mintPrice, uint _maxNFTPerMint, SaleState _saleState, uint _maxSupply) external onlyOwner {
        mintPrice = _mintPrice;
        maxNFTPerMint = _maxNFTPerMint;
        saleState = _saleState;
        maxSupply = _maxSupply;
    }
    function safeMint(address to) public onlyOwner {
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        uint share1 = balance * 1 / 100;
        uint share2 = balance * 15 / 100;
        payable(0XXXXXXX).transfer(share1);
        payable(0xAXXXXXXXXX).transfer(share1);
        payable(Owner).transfert(share2);
        payable(0xXXXXXXXX).transfer(balance - (share1 *2) - (share2));
            }
}
