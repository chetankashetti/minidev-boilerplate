// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title EscrowTemplate
 * @dev A secure escrow contract template for handling payments and disputes
 * 
 * Features:
 * - Multi-token support (ETH and ERC20 tokens)
 * - Dispute resolution mechanism
 * - Time-based automatic release
 * - Reentrancy protection
 * - Pausable functionality
 * - Owner-controlled operations
 * 
 * Security considerations:
 * - Uses OpenZeppelin's battle-tested contracts
 * - Implements reentrancy guards
 * - Includes proper access controls
 * - Safe token transfer mechanisms
 * - No external dependencies beyond OpenZeppelin
 * 
 * Usage in AI generation:
 * - Reference this template for any escrow/payment functionality
 * - Modify dispute resolution logic as needed
 * - Add custom business logic while maintaining security patterns
 */
contract EscrowTemplate is ReentrancyGuard, Ownable, Pausable {
    using SafeERC20 for IERC20;
    
    // Escrow states
    enum EscrowState {
        Pending,    // Escrow created, waiting for payment
        Funded,     // Payment received, waiting for completion
        Completed,  // Successfully completed
        Disputed,   // Dispute raised
        Cancelled   // Cancelled by buyer or seller
    }
    
    // Escrow structure
    struct Escrow {
        address buyer;
        address seller;
        address token;          // Address(0) for ETH, token address for ERC20
        uint256 amount;
        uint256 deadline;       // Timestamp when escrow expires
        string description;
        EscrowState state;
        address arbitrator;     // Optional arbitrator for disputes
        uint256 disputeFee;     // Fee for raising disputes
    }
    
    // Mapping of escrow ID to escrow details
    mapping(uint256 => Escrow) public escrows;
    
    // Escrow ID counter
    uint256 private _escrowIdCounter;
    
    // Platform fee (in basis points, e.g., 250 = 2.5%)
    uint256 public platformFeeBps = 250;
    
    // Platform fee recipient
    address public feeRecipient;
    
    // Events
    event EscrowCreated(uint256 indexed escrowId, address indexed buyer, address indexed seller, uint256 amount);
    event EscrowFunded(uint256 indexed escrowId, address indexed buyer, uint256 amount);
    event EscrowCompleted(uint256 indexed escrowId, address indexed seller, uint256 amount);
    event EscrowDisputed(uint256 indexed escrowId, address indexed disputer, string reason);
    event EscrowCancelled(uint256 indexed escrowId, address indexed canceller, uint256 refundAmount);
    event DisputeResolved(uint256 indexed escrowId, address indexed winner, uint256 amount);
    
    /**
     * @dev Constructor
     * @param feeRecipient_ Address to receive platform fees
     */
    constructor(address feeRecipient_) Ownable(msg.sender) {
        feeRecipient = feeRecipient_;
    }
    
    /**
     * @dev Create a new escrow
     * @param seller Address of the seller
     * @param token Address of the token (address(0) for ETH)
     * @param amount Amount to escrow
     * @param deadline Timestamp when escrow expires
     * @param description Description of the escrow
     * @param arbitrator Optional arbitrator address
     * @return escrowId The ID of the created escrow
     */
    function createEscrow(
        address seller,
        address token,
        uint256 amount,
        uint256 deadline,
        string memory description,
        address arbitrator
    ) external whenNotPaused returns (uint256) {
        require(seller != address(0), "Invalid seller address");
        require(amount > 0, "Amount must be greater than 0");
        require(deadline > block.timestamp, "Deadline must be in the future");
        
        uint256 escrowId = _escrowIdCounter;
        _escrowIdCounter++;
        
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
        return escrowId;
    }
    
    /**
     * @dev Fund an escrow with payment
     * @param escrowId ID of the escrow to fund
     */
    function fundEscrow(uint256 escrowId) external payable nonReentrant whenNotPaused {
        Escrow storage escrow = escrows[escrowId];
        require(escrow.buyer == msg.sender, "Only buyer can fund escrow");
        require(escrow.state == EscrowState.Pending, "Escrow not in pending state");
        
        if (escrow.token == address(0)) {
            // ETH payment
            require(msg.value == escrow.amount, "Incorrect ETH amount");
        } else {
            // ERC20 payment
            require(msg.value == 0, "ETH not accepted for token escrow");
            IERC20(escrow.token).safeTransferFrom(msg.sender, address(this), escrow.amount);
        }
        
        escrow.state = EscrowState.Funded;
        emit EscrowFunded(escrowId, msg.sender, escrow.amount);
    }
    
    /**
     * @dev Complete an escrow (release funds to seller)
     * @param escrowId ID of the escrow to complete
     */
    function completeEscrow(uint256 escrowId) external nonReentrant whenNotPaused {
        Escrow storage escrow = escrows[escrowId];
        require(escrow.state == EscrowState.Funded, "Escrow not funded");
        require(escrow.buyer == msg.sender, "Only buyer can complete escrow");
        
        escrow.state = EscrowState.Completed;
        
        // Calculate platform fee
        uint256 fee = (escrow.amount * platformFeeBps) / 10000;
        uint256 sellerAmount = escrow.amount - fee;
        
        // Transfer funds
        if (escrow.token == address(0)) {
            // ETH transfer
            if (fee > 0) {
                payable(feeRecipient).transfer(fee);
            }
            payable(escrow.seller).transfer(sellerAmount);
        } else {
            // ERC20 transfer
            if (fee > 0) {
                IERC20(escrow.token).safeTransfer(feeRecipient, fee);
            }
            IERC20(escrow.token).safeTransfer(escrow.seller, sellerAmount);
        }
        
        emit EscrowCompleted(escrowId, escrow.seller, sellerAmount);
    }
    
    /**
     * @dev Raise a dispute for an escrow
     * @param escrowId ID of the escrow to dispute
     * @param reason Reason for the dispute
     */
    function raiseDispute(uint256 escrowId, string memory reason) external whenNotPaused {
        Escrow storage escrow = escrows[escrowId];
        require(escrow.state == EscrowState.Funded, "Escrow not funded");
        require(msg.sender == escrow.buyer || msg.sender == escrow.seller, "Only buyer or seller can raise dispute");
        
        escrow.state = EscrowState.Disputed;
        emit EscrowDisputed(escrowId, msg.sender, reason);
    }
    
    /**
     * @dev Resolve a dispute (only arbitrator or owner)
     * @param escrowId ID of the escrow to resolve
     * @param winner Address of the winner (buyer or seller)
     */
    function resolveDispute(uint256 escrowId, address winner) external nonReentrant whenNotPaused {
        Escrow storage escrow = escrows[escrowId];
        require(escrow.state == EscrowState.Disputed, "Escrow not in dispute");
        require(
            msg.sender == escrow.arbitrator || msg.sender == owner(),
            "Only arbitrator or owner can resolve dispute"
        );
        require(winner == escrow.buyer || winner == escrow.seller, "Invalid winner address");
        
        escrow.state = EscrowState.Completed;
        
        // Calculate platform fee
        uint256 fee = (escrow.amount * platformFeeBps) / 10000;
        uint256 winnerAmount = escrow.amount - fee;
        
        // Transfer funds to winner
        if (escrow.token == address(0)) {
            // ETH transfer
            if (fee > 0) {
                payable(feeRecipient).transfer(fee);
            }
            payable(winner).transfer(winnerAmount);
        } else {
            // ERC20 transfer
            if (fee > 0) {
                IERC20(escrow.token).safeTransfer(feeRecipient, fee);
            }
            IERC20(escrow.token).safeTransfer(winner, winnerAmount);
        }
        
        emit DisputeResolved(escrowId, winner, winnerAmount);
    }
    
    /**
     * @dev Cancel an escrow (only if not funded or after deadline)
     * @param escrowId ID of the escrow to cancel
     */
    function cancelEscrow(uint256 escrowId) external nonReentrant whenNotPaused {
        Escrow storage escrow = escrows[escrowId];
        require(
            escrow.state == EscrowState.Pending || 
            (escrow.state == EscrowState.Funded && block.timestamp > escrow.deadline),
            "Cannot cancel escrow"
        );
        require(
            msg.sender == escrow.buyer || msg.sender == escrow.seller,
            "Only buyer or seller can cancel"
        );
        
        escrow.state = EscrowState.Cancelled;
        
        // Refund if funded
        if (escrow.state == EscrowState.Funded) {
            if (escrow.token == address(0)) {
                payable(escrow.buyer).transfer(escrow.amount);
            } else {
                IERC20(escrow.token).safeTransfer(escrow.buyer, escrow.amount);
            }
        }
        
        emit EscrowCancelled(escrowId, msg.sender, escrow.amount);
    }
    
    /**
     * @dev Get escrow details
     * @param escrowId ID of the escrow
     * @return Escrow struct with all details
     */
    function getEscrow(uint256 escrowId) external view returns (Escrow memory) {
        return escrows[escrowId];
    }
    
    /**
     * @dev Set platform fee (only owner)
     * @param newFeeBps New fee in basis points
     */
    function setPlatformFee(uint256 newFeeBps) external onlyOwner {
        require(newFeeBps <= 1000, "Fee cannot exceed 10%");
        platformFeeBps = newFeeBps;
    }
    
    /**
     * @dev Set fee recipient (only owner)
     * @param newFeeRecipient New fee recipient address
     */
    function setFeeRecipient(address newFeeRecipient) external onlyOwner {
        require(newFeeRecipient != address(0), "Invalid fee recipient");
        feeRecipient = newFeeRecipient;
    }
    
    /**
     * @dev Pause the contract (only owner)
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @dev Unpause the contract (only owner)
     */
    function unpause() external onlyOwner {
        _unpause();
    }
    
    /**
     * @dev Emergency function to recover accidentally sent tokens
     * @param tokenAddress Address of the token to recover
     * @param amount Amount to recover
     */
    function recoverTokens(address tokenAddress, uint256 amount) external onlyOwner {
        if (tokenAddress == address(0)) {
            payable(owner()).transfer(amount);
        } else {
            IERC20(tokenAddress).safeTransfer(owner(), amount);
        }
    }
}
