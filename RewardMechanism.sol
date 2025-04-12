// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;



// Interface including functions needed from UCoin contract
interface IERC20RewardSource {
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function balanceOf(address account) external view returns (uint); // Keep for optional balance check
}

// Interface for basic transfer needed by withdrawExcessTokens
interface IERC20Basic {
     function transfer(address recipient, uint amount) external returns (bool);
     function balanceOf(address account) external view returns (uint);
}


contract RewardMechanism {
    address public owner;
    IERC20RewardSource public immutable ucoin; // Use the interface with allowance/transferFrom
    address public immutable rewardTreasury; // Address holding the reward UCoin

    // Mapping: User address => Amount of UCoin they are eligible to claim
    mapping(address => uint) public availableRewards;

    // Mapping: User address => Amount of UCoin they have already claimed
    mapping(address => uint) public claimedRewards; // Track total claimed for history/auditing

    event RewardAllocated(address indexed user, uint amount);
    event RewardClaimed(address indexed user, uint amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner); // Good practice

    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized: Only owner action");
        _;
    }

    /**
     * @notice Contract constructor
     * @param _tokenAddress The address of the UCoin ERC20 contract.
     * @param _rewardTreasury The address holding the UCoin funds for rewards.
     */
    constructor(address _tokenAddress, address _rewardTreasury) {
        require(_tokenAddress != address(0), "RM: Invalid token address");
        require(_rewardTreasury != address(0), "RM: Invalid reward treasury address");
        owner = msg.sender;
        ucoin = IERC20RewardSource(_tokenAddress);
        rewardTreasury = _rewardTreasury; // Store the treasury address
    }

    /**
     * @notice Allocates rewards to a user, adding to any existing available amount.
     * @dev Only the owner can call this. Does not move funds.
     * @param _user The address of the user to receive the reward allocation.
     * @param _amount The amount of UCoin to make available for claiming.
     */
    function allocateReward(address _user, uint _amount) public onlyOwner {
        require(_user != address(0), "RM: Invalid user address");
        require(_amount > 0, "RM: Amount must be positive");

        availableRewards[_user] += _amount;
        emit RewardAllocated(_user, _amount);
    }

    /**
    * @notice Allows a user to claim their available UCoin rewards.
    * @dev User calls this function directly. Pulls funds from rewardTreasury via transferFrom.
    * @dev Requires rewardTreasury to have approved this contract address on the UCoin contract.
    */
    function claimReward() public {
        uint amountToClaim = availableRewards[msg.sender];
        require(amountToClaim > 0, "RM: No rewards available to claim");

        // Checks-Effects-Interactions Pattern:
        // 1. Checks
        // Check if this contract has sufficient *allowance* from the treasury
        uint currentAllowance = ucoin.allowance(rewardTreasury, address(this));
        require(currentAllowance >= amountToClaim, "RM: Insufficient allowance from treasury");

        // Optional but recommended: Check if treasury has enough balance
        uint treasuryBalance = ucoin.balanceOf(rewardTreasury);
        require(treasuryBalance >= amountToClaim, "RM: Insufficient balance in treasury for reward");

        // 2. Effects (Update state BEFORE external call)
        availableRewards[msg.sender] = 0; // Clear available amount *before* transfer
        claimedRewards[msg.sender] += amountToClaim; // Update total claimed amount

        // 3. Interaction - Use transferFrom to pull funds from treasury
        // Transfers UCoin directly FROM rewardTreasury TO msg.sender (the user)
        bool sent = ucoin.transferFrom(rewardTreasury, msg.sender, amountToClaim);
        // This will fail if allowance was decreased concurrently or if treasury balance dropped below amountToClaim
        // after the check above but before this line (less likely but possible in high contention scenarios)
        require(sent, "RM: UCoin transferFrom failed");

        emit RewardClaimed(msg.sender, amountToClaim);
    }

    /**
     * @notice Allows the owner to withdraw UCoin *accidentally sent to this contract address*.
     * @dev This is NOT for withdrawing from the treasury's allowance.
     * @param _to The address to send the rescued tokens to.
     * @param _amount The amount of UCoin to withdraw from this contract's balance.
     */
    function withdrawExcessTokens(address _to, uint _amount) public onlyOwner {
         require(_to != address(0), "RM: Invalid recipient address");
         // Use the basic interface for standard transfer
         IERC20Basic token = IERC20Basic(address(ucoin));
         uint contractBalance = token.balanceOf(address(this));
         require(contractBalance >= _amount, "RM: Withdraw amount exceeds contract balance");

         bool sent = token.transfer(_to, _amount);
         require(sent, "RM: UCoin transfer failed");
    }

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     * @dev Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    // Optional: Add a function for owner to renounce ownership if needed (use with caution)
    // function renounceOwnership() public virtual onlyOwner {
    //     address oldOwner = owner;
    //     owner = address(0);
    //     emit OwnershipTransferred(oldOwner, address(0));
    // }
}
