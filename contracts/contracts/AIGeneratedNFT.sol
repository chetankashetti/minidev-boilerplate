// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./ERC721Template.sol";

/**
 * @title AIGeneratedNFT
 * @dev Example of how AI would extend the ERC721Template with custom functionality
 * This demonstrates the AI's ability to add business logic while maintaining security
 */
contract AIGeneratedNFT is ERC721Template {
    address public artist;
    uint256 public constant MINT_PRICE = 0.1 ether;
    uint256 public constant MAX_MINTS_PER_ADDRESS = 5;
    
    mapping(address => uint256) public mintCount;
    
    /**
     * @dev Constructor that extends the base template
     * @param name_ Collection name
     * @param symbol_ Collection symbol
     * @param baseTokenURI_ Base URI for metadata
     * @param artist_ Artist address for royalty collection
     */
    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseTokenURI_,
        address artist_
    ) ERC721Template(name_, symbol_, baseTokenURI_) {
        artist = artist_;
    }
    
    
    /**
     * @dev Mint NFT with price (AI-added functionality)
     * @param tokenURI URI for the token metadata
     */
    function mintWithPrice(string memory tokenURI) external payable {
        require(msg.value >= MINT_PRICE, "Insufficient payment");
        require(mintCount[msg.sender] < MAX_MINTS_PER_ADDRESS, "Max mints per address exceeded");
        require(ERC721Enumerable.totalSupply() < MAX_SUPPLY, "Maximum supply reached");
        
        // Increment mint count for this address
        mintCount[msg.sender]++;
        
        // Mint the NFT using parent's safeMint (only owner can call)
        // This is a limitation - in real AI implementation, we'd need to handle this differently
        // For now, we'll use a different approach
        require(ERC721Enumerable.totalSupply() < MAX_SUPPLY, "Maximum supply reached");
        
        uint256 tokenId = ERC721Enumerable.totalSupply();
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenURI);
        
        // Send payment to artist
        if (msg.value > 0) {
            payable(artist).transfer(msg.value);
        }
    }
    
    /**
     * @dev Batch mint with price (AI-added functionality)
     * @param tokenURIs Array of URIs for token metadata
     */
    function batchMintWithPrice(string[] memory tokenURIs) external payable {
        require(msg.value >= MINT_PRICE * tokenURIs.length, "Insufficient payment");
        require(mintCount[msg.sender] + tokenURIs.length <= MAX_MINTS_PER_ADDRESS, "Max mints per address exceeded");
        require(ERC721Enumerable.totalSupply() + tokenURIs.length <= MAX_SUPPLY, "Maximum supply reached");
        
        // Increment mint count for this address
        mintCount[msg.sender] += tokenURIs.length;
        
        // Mint the NFTs using internal logic
        for (uint256 i = 0; i < tokenURIs.length; i++) {
            uint256 tokenId = ERC721Enumerable.totalSupply();
            _safeMint(msg.sender, tokenId);
            _setTokenURI(tokenId, tokenURIs[i]);
        }
        
        // Send payment to artist
        if (msg.value > 0) {
            payable(artist).transfer(msg.value);
        }
    }
    
    /**
     * @dev Set new artist address (only owner)
     * @param newArtist New artist address
     */
    function setArtist(address newArtist) external onlyOwner {
        require(newArtist != address(0), "Invalid artist address");
        artist = newArtist;
    }
    
    /**
     * @dev Get minting information
     * @return mintPrice Current mint price
     * @return maxMintsPerAddress Maximum mints per address
     * @return artistAddress Current artist address
     */
    function getMintingInfo() external view returns (
        uint256 mintPrice,
        uint256 maxMintsPerAddress,
        address artistAddress
    ) {
        return (MINT_PRICE, MAX_MINTS_PER_ADDRESS, artist);
    }
    
    /**
     * @dev Get mint count for an address
     * @param account Address to check
     * @return count Number of NFTs minted by this address
     */
    function getMintCount(address account) external view returns (uint256 count) {
        return mintCount[account];
    }
}
