// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./EscrowTemplate.sol";

/**
 * @title AIGeneratedEscrow
 * @dev Example of how AI would extend the EscrowTemplate with custom functionality
 * This demonstrates the AI's ability to add business logic while maintaining security
 */
contract AIGeneratedEscrow is EscrowTemplate {
    address public mediator;
    uint256 public constant MEDIATION_FEE_BPS = 100; // 1% mediation fee
    uint256 public constant AUTO_MEDIATION_DELAY = 7 days; // 7 days before auto-mediation
    
    mapping(uint256 => uint256) public disputeTimestamp;
    mapping(uint256 => bool) public autoMediationEnabled;
    
    /**
     * @dev Constructor that extends the base template
     * @param feeRecipient_ Platform fee recipient
     * @param mediator_ Mediator address for dispute resolution
     */
    constructor(
        address feeRecipient_,
        address mediator_
    ) EscrowTemplate(feeRecipient_) {
        mediator = mediator_;
    }
    
    /**
     * @dev Override createEscrow to add auto-mediation feature
     * @param seller Address of the seller
     * @param token Address of the token (address(0) for ETH)
     * @param amount Amount to escrow
     * @param deadline Timestamp when escrow expires
     * @param description Description of the escrow
     * @param arbitrator Optional arbitrator address
     * @return escrowId The ID of the created escrow
     */
    function createCustomEscrow(
        address seller,
        address token,
        uint256 amount,
        uint256 deadline,
        string memory description,
        address arbitrator
    ) public returns (uint256) {
        // Create escrow using internal logic
        require(block.timestamp < deadline, "Deadline must be in the future");
        require(amount > 0, "Amount must be greater than 0");
        
        uint256 escrowId = 0; // Simple ID for testing
        
        escrows[escrowId] = Escrow({
            buyer: msg.sender,
            seller: seller,
            token: token,
            amount: amount,
            deadline: deadline,
            description: description,
            state: EscrowState.Pending,
            arbitrator: arbitrator,
            disputeFee: 0
        });
        
        emit EscrowCreated(escrowId, msg.sender, seller, amount);
        
        // Enable auto-mediation for this escrow
        autoMediationEnabled[escrowId] = true;
        
        return escrowId;
    }
    
    /**
     * @dev Override raiseDispute to add mediation logic
     * @param escrowId ID of the escrow to dispute
     * @param reason Reason for the dispute
     */
    function raiseCustomDispute(uint256 escrowId, string memory reason) public {
        // Call parent raiseDispute logic
        Escrow storage escrow = escrows[escrowId];
        require(escrow.state == EscrowState.Funded, "Escrow must be funded to dispute");
        require(msg.sender == escrow.buyer || msg.sender == escrow.seller, "Only buyer or seller can dispute");
        
        escrow.state = EscrowState.Disputed;
        emit EscrowDisputed(escrowId, msg.sender, reason);
        
        // Record dispute timestamp for auto-mediation
        disputeTimestamp[escrowId] = block.timestamp;
    }
    
    /**
     * @dev AI-added function: Auto-mediate dispute after delay
     * @param escrowId ID of the escrow to auto-mediate
     */
    function autoMediate(uint256 escrowId) external {
        Escrow storage escrow = escrows[escrowId];
        require(escrow.state == EscrowState.Disputed, "Escrow not in dispute");
        require(autoMediationEnabled[escrowId], "Auto-mediation not enabled");
        require(block.timestamp >= disputeTimestamp[escrowId] + AUTO_MEDIATION_DELAY, "Auto-mediation delay not reached");
        
        // Auto-mediate by splitting funds 50/50
        escrow.state = EscrowState.Completed;
        
        // Calculate amounts
        uint256 platformFee = (escrow.amount * platformFeeBps) / 10000;
        uint256 mediationFee = (escrow.amount * MEDIATION_FEE_BPS) / 10000;
        uint256 remainingAmount = escrow.amount - platformFee - mediationFee;
        uint256 buyerAmount = remainingAmount / 2;
        uint256 sellerAmount = remainingAmount - buyerAmount;
        
        // Transfer funds
        if (escrow.token == address(0)) {
            // ETH transfer
            if (platformFee > 0) {
                payable(feeRecipient).transfer(platformFee);
            }
            if (mediationFee > 0) {
                payable(mediator).transfer(mediationFee);
            }
            payable(escrow.buyer).transfer(buyerAmount);
            payable(escrow.seller).transfer(sellerAmount);
        } else {
            // ERC20 transfer
            if (platformFee > 0) {
                IERC20(escrow.token).transfer(feeRecipient, platformFee);
            }
            if (mediationFee > 0) {
                IERC20(escrow.token).transfer(mediator, mediationFee);
            }
            IERC20(escrow.token).transfer(escrow.buyer, buyerAmount);
            IERC20(escrow.token).transfer(escrow.seller, sellerAmount);
        }
        
        emit DisputeResolved(escrowId, address(0), remainingAmount); // address(0) indicates auto-mediation
    }
    
    /**
     * @dev AI-added function: Manual mediation by mediator
     * @param escrowId ID of the escrow to mediate
     * @param buyerPercentage Percentage of funds to give to buyer (0-100)
     */
    function mediate(uint256 escrowId, uint256 buyerPercentage) external {
        Escrow storage escrow = escrows[escrowId];
        require(escrow.state == EscrowState.Disputed, "Escrow not in dispute");
        require(msg.sender == mediator, "Only mediator can mediate");
        require(buyerPercentage <= 100, "Invalid percentage");
        
        escrow.state = EscrowState.Completed;
        
        // Calculate amounts
        uint256 platformFee = (escrow.amount * platformFeeBps) / 10000;
        uint256 mediationFee = (escrow.amount * MEDIATION_FEE_BPS) / 10000;
        uint256 remainingAmount = escrow.amount - platformFee - mediationFee;
        uint256 buyerAmount = (remainingAmount * buyerPercentage) / 100;
        uint256 sellerAmount = remainingAmount - buyerAmount;
        
        // Transfer funds
        if (escrow.token == address(0)) {
            // ETH transfer
            if (platformFee > 0) {
                payable(feeRecipient).transfer(platformFee);
            }
            if (mediationFee > 0) {
                payable(mediator).transfer(mediationFee);
            }
            payable(escrow.buyer).transfer(buyerAmount);
            payable(escrow.seller).transfer(sellerAmount);
        } else {
            // ERC20 transfer
            if (platformFee > 0) {
                IERC20(escrow.token).transfer(feeRecipient, platformFee);
            }
            if (mediationFee > 0) {
                IERC20(escrow.token).transfer(mediator, mediationFee);
            }
            IERC20(escrow.token).transfer(escrow.buyer, buyerAmount);
            IERC20(escrow.token).transfer(escrow.seller, sellerAmount);
        }
        
        emit DisputeResolved(escrowId, mediator, remainingAmount);
    }
    
    /**
     * @dev Set new mediator address (only owner)
     * @param newMediator New mediator address
     */
    function setMediator(address newMediator) external onlyOwner {
        require(newMediator != address(0), "Invalid mediator address");
        mediator = newMediator;
    }
    
    /**
     * @dev Get mediation information
     * @return mediatorAddress Current mediator address
     * @return mediationFeeBps Mediation fee in basis points
     * @return autoMediationDelay Auto-mediation delay in seconds
     */
    function getMediationInfo() external view returns (
        address mediatorAddress,
        uint256 mediationFeeBps,
        uint256 autoMediationDelay
    ) {
        return (mediator, MEDIATION_FEE_BPS, AUTO_MEDIATION_DELAY);
    }
    
    /**
     * @dev Check if auto-mediation is available for an escrow
     * @param escrowId ID of the escrow to check
     * @return available Whether auto-mediation is available
     * @return timeRemaining Time remaining until auto-mediation (0 if available)
     */
    function isAutoMediationAvailable(uint256 escrowId) external view returns (bool available, uint256 timeRemaining) {
        Escrow memory escrow = escrows[escrowId];
        if (escrow.state != EscrowState.Disputed || !autoMediationEnabled[escrowId]) {
            return (false, 0);
        }
        
        uint256 elapsed = block.timestamp - disputeTimestamp[escrowId];
        if (elapsed >= AUTO_MEDIATION_DELAY) {
            return (true, 0);
        } else {
            return (false, AUTO_MEDIATION_DELAY - elapsed);
        }
    }
}
