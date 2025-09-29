// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./ERC20Template.sol";

/**
 * @title AIGeneratedToken
 * @dev Example of how AI would extend the ERC20Template with custom functionality
 * This demonstrates the AI's ability to add business logic while maintaining security
 */
contract AIGeneratedToken is ERC20Template {
    address public treasury;
    uint256 public constant TRANSFER_FEE_BPS = 250; // 2.5% fee on transfers
    
    /**
     * @dev Constructor that extends the base template
     * @param name_ Token name
     * @param symbol_ Token symbol
     * @param decimals_ Number of decimals
     * @param initialSupply_ Initial token supply
     * @param treasury_ Treasury address for fee collection
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 initialSupply_,
        address treasury_
    ) ERC20Template(name_, symbol_, decimals_, initialSupply_) {
        treasury = treasury_;
    }
    
    /**
     * @dev Override transfer to add fee collection
     * @param to Recipient address
     * @param amount Amount to transfer
     * @return success Whether the transfer was successful
     */
    function transfer(address to, uint256 amount) public override returns (bool success) {
        uint256 fee = (amount * TRANSFER_FEE_BPS) / 10000;
        uint256 transferAmount = amount - fee;
        
        // Transfer the fee to treasury
        if (fee > 0) {
            super.transfer(treasury, fee);
        }
        
        // Transfer the remaining amount
        return super.transfer(to, transferAmount);
    }
    
    /**
     * @dev Override transferFrom to add fee collection
     * @param from Sender address
     * @param to Recipient address
     * @param amount Amount to transfer
     * @return success Whether the transfer was successful
     */
    function transferFrom(address from, address to, uint256 amount) public override returns (bool success) {
        uint256 fee = (amount * TRANSFER_FEE_BPS) / 10000;
        uint256 transferAmount = amount - fee;
        
        // Transfer the fee to treasury
        if (fee > 0) {
            super.transferFrom(from, treasury, fee);
        }
        
        // Transfer the remaining amount
        return super.transferFrom(from, to, transferAmount);
    }
    
    /**
     * @dev Set new treasury address (only owner)
     * @param newTreasury New treasury address
     */
    function setTreasury(address newTreasury) external onlyOwner {
        require(newTreasury != address(0), "Invalid treasury address");
        treasury = newTreasury;
    }
    
    /**
     * @dev Get transfer fee information
     * @return feeBps Transfer fee in basis points
     * @return treasuryAddress Current treasury address
     */
    function getTransferFeeInfo() external view returns (uint256 feeBps, address treasuryAddress) {
        return (TRANSFER_FEE_BPS, treasury);
    }
}
