// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StablecoinEscrow is Ownable {
    IERC20 public stablecoin;

    enum EscrowState { Created, Funded, Completed, Cancelled }

    struct Escrow {
        address buyer;
        address seller;
        uint256 amount;
        EscrowState state;
    }

    Escrow[] public escrows;

    event EscrowCreated(uint256 escrowId, address indexed buyer, address indexed seller, uint256 amount);
    event EscrowFunded(uint256 escrowId);
    event EscrowCompleted(uint256 escrowId);
    event EscrowCancelled(uint256 escrowId);
    event CheckBalance(string text, uint amount);

    constructor(address _stablecoinAddress) {
        stablecoin = IERC20(_stablecoinAddress);
    }

    // Create a new stablecoin escrow
    function createEscrow(address _seller, uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than 0");
        require(_seller != address(0), "Invalid seller address");
        require(stablecoin.transferFrom(msg.sender, address(this), _amount), "Transfer failed");

        uint256 escrowId = escrows.length;
        escrows.push(Escrow(msg.sender, _seller, _amount, EscrowState.Created));

        emit EscrowCreated(escrowId, msg.sender, _seller, _amount);
    }

    // Fund the stablecoin escrow
    function fundEscrow(uint256 _escrowId) external {
        require(_escrowId < escrows.length, "Invalid escrow ID");

        Escrow storage escrow = escrows[_escrowId];
        require(escrow.state == EscrowState.Created, "Escrow is not in the Created state");
        require(escrow.buyer == msg.sender, "Only the buyer can fund the escrow");

        escrow.state = EscrowState.Funded;

        emit EscrowFunded(_escrowId);
    }

    // Complete the stablecoin escrow
    function completeEscrow(uint256 _escrowId) external onlyOwner {
        require(_escrowId < escrows.length, "Invalid escrow ID");

        Escrow storage escrow = escrows[_escrowId];
        require(escrow.state == EscrowState.Funded, "Escrow is not in the Funded state");

        // Transfer the stablecoins to the seller
        require(stablecoin.transfer(escrow.seller, escrow.amount), "Transfer to seller failed");

        escrow.state = EscrowState.Completed;

        emit EscrowCompleted(_escrowId);
    }

    // Cancel the stablecoin escrow
    function cancelEscrow(uint256 _escrowId) external {
        require(_escrowId < escrows.length, "Invalid escrow ID");

        Escrow storage escrow = escrows[_escrowId];
        require(msg.sender == escrow.buyer || msg.sender == owner(), "Only buyer or owner can cancel");
        require(escrow.state != EscrowState.Completed, "Escrow is already completed");

        escrow.state = EscrowState.Cancelled;

        // Transfer stablecoins back to the buyer
        require(stablecoin.transfer(escrow.buyer, escrow.amount), "Transfer to buyer failed");

        emit EscrowCancelled(_escrowId);
    }
    
    function getBalance(address user_account) external returns (uint){
        require(user_account != address(0), "Invalid address");
        uint user_bal = user_account.balance;
        emit CheckBalance(user_bal);
        return (user_bal);
    }
}
