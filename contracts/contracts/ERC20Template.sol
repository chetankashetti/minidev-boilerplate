// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title ERC20Template
 * @dev A secure, feature-rich ERC20 token template based on OpenZeppelin standards
 * 
 * Features:
 * - Standard ERC20 functionality
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
 * - Reference this template for any token-based functionality
 * - Modify name, symbol, and initial supply as needed
 * - Add custom logic while maintaining security patterns
 */
contract ERC20Template is ERC20, ERC20Burnable, Ownable, Pausable {
    uint8 private _decimals;
    uint256 public constant MAX_SUPPLY = 1000000000 * 10**18; // 1 billion tokens max
    
    /**
     * @dev Constructor that initializes the token
     * @param name_ Token name (e.g., "MyToken")
     * @param symbol_ Token symbol (e.g., "MTK")
     * @param decimals_ Number of decimals (typically 18)
     * @param initialSupply_ Initial token supply to mint to deployer
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 initialSupply_
    ) ERC20(name_, symbol_) Ownable(msg.sender) {
        _decimals = decimals_;
        
        // Validate initial supply
        require(initialSupply_ <= MAX_SUPPLY, "Initial supply exceeds maximum");
        
        // Mint initial supply to deployer
        _mint(msg.sender, initialSupply_);
    }
    
    /**
     * @dev Returns the number of decimals used
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
    
    /**
     * @dev Mint new tokens (only owner)
     * @param to Address to mint tokens to
     * @param amount Amount of tokens to mint
     */
    function mint(address to, uint256 amount) public onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY, "Minting would exceed maximum supply");
        _mint(to, amount);
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
        address from,
        address to,
        uint256 value
    ) internal virtual override {
        // Check if transfers are paused
        require(!paused(), "Token transfers are paused");
        
        super._update(from, to, value);
    }
    
    /**
     * @dev Emergency function to recover accidentally sent ERC20 tokens
     * @param tokenAddress Address of the token to recover
     * @param amount Amount to recover
     */
    function recoverERC20(address tokenAddress, uint256 amount) external onlyOwner {
        IERC20(tokenAddress).transfer(owner(), amount);
    }
    
    /**
     * @dev Get token information
     * @return name Token name
     * @return symbol Token symbol
     * @return tokenDecimals Number of decimals
     * @return totalSupply Current total supply
     * @return maxSupply Maximum possible supply
     */
    function getTokenInfo() external view returns (
        string memory name,
        string memory symbol,
        uint8 tokenDecimals,
        uint256 totalSupply,
        uint256 maxSupply
    ) {
        return (
            ERC20.name(),
            ERC20.symbol(),
            _decimals,
            ERC20.totalSupply(),
            MAX_SUPPLY
        );
    }
}
