// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title ERC721Template
 * @dev A secure, feature-rich ERC721 NFT template based on OpenZeppelin standards
 * 
 * Features:
 * - Standard ERC721 functionality
 * - Enumerable tokens (can iterate through all tokens)
 * - URI storage for metadata
 * - Burnable tokens
 * - Pausable transfers (emergency stop)
 * - Owner-controlled minting
 * - Access control
 * 
 * Security considerations:
 * - Uses OpenZeppelin's battle-tested contracts
 * - Implements proper access controls
 * - Includes emergency pause functionality
 * - No external dependencies beyond OpenZeppelin
 * 
 * Usage in AI generation:
 * - Reference this template for any NFT-based functionality
 * - Modify name, symbol, and base URI as needed
 * - Add custom logic while maintaining security patterns
 */
contract ERC721Template is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Burnable,
    Ownable,
    Pausable
{
    uint256 internal _tokenIdCounter; // Changed to internal for child contract access
    string private _baseTokenURI;
    uint256 public constant MAX_SUPPLY = 10000; // Maximum number of NFTs
    
    /**
     * @dev Constructor that initializes the NFT contract
     * @param name_ NFT collection name (e.g., "MyNFTCollection")
     * @param symbol_ NFT collection symbol (e.g., "MNC")
     * @param baseTokenURI_ Base URI for token metadata
     */
    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseTokenURI_
    ) ERC721(name_, symbol_) Ownable(msg.sender) {
        _baseTokenURI = baseTokenURI_;
    }
    
    /**
     * @dev Set the base URI for all tokens
     * @param baseTokenURI_ New base URI
     */
    function setBaseURI(string memory baseTokenURI_) public onlyOwner {
        _baseTokenURI = baseTokenURI_;
    }
    
    /**
     * @dev Get the base URI for tokens
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
    
    /**
     * @dev Internal mint function that can be called by child contracts
     * This allows child contracts to implement custom minting logic while maintaining security
     * @param to Address to mint the NFT to
     * @param tokenUri URI for the token metadata
     */
    function _mintToken(address to, string memory tokenUri) internal {
        require(_tokenIdCounter < MAX_SUPPLY, "Maximum supply reached");

        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenUri);
    }

    /**
     * @dev Mint a new NFT to a specific address (owner-only)
     * @param to Address to mint the NFT to
     * @param tokenUri URI for the token metadata
     */
    function safeMint(address to, string memory tokenUri) public virtual onlyOwner {
        _mintToken(to, tokenUri);
    }
    
    /**
     * @dev Mint multiple NFTs in a batch
     * @param to Address to mint the NFTs to
     * @param tokenURIs Array of URIs for token metadata
     */
    function batchMint(address to, string[] memory tokenURIs) public onlyOwner {
        require(_tokenIdCounter + tokenURIs.length <= MAX_SUPPLY, "Batch minting would exceed maximum supply");

        for (uint256 i = 0; i < tokenURIs.length; i++) {
            _mintToken(to, tokenURIs[i]);
        }
    }
    
    /**
     * @dev Pause all token transfers (emergency function)
     */
    function pause() public onlyOwner {
        _pause();
    }
    
    /**
     * @dev Unpause token transfers
     */
    function unpause() public onlyOwner {
        _unpause();
    }
    
    /**
     * @dev Hook that is called before any transfer of tokens
     * Override to add custom logic (e.g., fees, restrictions)
     */
    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal virtual override(ERC721, ERC721Enumerable) returns (address) {
        // Check if transfers are paused
        require(!paused(), "Token transfers are paused");
        
        return super._update(to, tokenId, auth);
    }
    
    function _increaseBalance(address account, uint128 value) internal virtual override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }
    
    /**
     * @dev Get the current token ID counter
     * @return Current token ID (next token will be this ID)
     */
    function getCurrentTokenId() public view returns (uint256) {
        return _tokenIdCounter;
    }
    
    /**
     * @dev Get collection information
     * @return name Collection name
     * @return symbol Collection symbol
     * @return totalSupply Current total supply
     * @return maxSupply Maximum possible supply
     * @return baseURI Base URI for metadata
     */
    function getCollectionInfo() external view returns (
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        uint256 maxSupply,
        string memory baseURI
    ) {
        return (
            ERC721.name(),
            ERC721.symbol(),
            ERC721Enumerable.totalSupply(),
            MAX_SUPPLY,
            _baseTokenURI
        );
    }
    
    // The following functions are overrides required by Solidity.
    
    
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        // Return the stored token URI directly without any concatenation
        return ERC721URIStorage.tokenURI(tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
