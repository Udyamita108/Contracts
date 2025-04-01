// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    function balanceOf(address account) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
}

contract RewardMechanism {
    address public owner;
    IERC20 public ucoin;

    struct WithdrawalRequest {
        address user;
        uint amount;
        bool approved;
    }

    mapping(address => WithdrawalRequest) public requests;
    event WithdrawalRequested(address indexed user, uint amount);
    event WithdrawalApproved(address indexed user, uint amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can approve");
        _;
    }

    constructor(address _tokenAddress) {
        owner = msg.sender;
        ucoin = IERC20(_tokenAddress);
    }

    function requestWithdrawal(uint _amount) public {
        require(_amount > 0, "Amount must be greater than zero");
        require(ucoin.balanceOf(owner) >= _amount, "Owner has insufficient funds");

        requests[msg.sender] = WithdrawalRequest(msg.sender, _amount, false);
        emit WithdrawalRequested(msg.sender, _amount);
    }

    function approveWithdrawal(address _user) public onlyOwner {
        WithdrawalRequest storage request = requests[_user];
        require(request.amount > 0, "No withdrawal request found");
        require(!request.approved, "Already approved");
        require(ucoin.allowance(owner, address(this)) >= request.amount, "Contract not approved to spend UCoin");

        request.approved = true;
        require(ucoin.transferFrom(owner, request.user, request.amount), "Transfer failed");
        
        emit WithdrawalApproved(request.user, request.amount);
    }
}
