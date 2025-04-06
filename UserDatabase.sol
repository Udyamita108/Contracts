// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "hardhat/console.sol"; // Optional: For debugging during development

contract UserDatabase {
    struct User {
        address wallet;
        string username;
        uint xp;
    }

    mapping(address => User) public users;
    address[] private userAddresses;
    // Optional but recommended for efficient removal:
    mapping(address => uint) private userIndex; // Maps address to its index in userAddresses

    address public owner;

    // --- Events ---
    event UserRegistered(address indexed userAddress, string username);
    event UserRemoved(address indexed userAddress);
    event XPUpdated(address indexed userAddress, uint newXP);
    event XPIncremented(address indexed userAddress, uint amount, uint newXP);


    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized: Only owner action");
        _;
    }

    constructor() {
        owner = msg.sender; // Set deployer as the owner
    }

    function setUser(string memory _username) public {
        require(users[msg.sender].wallet == address(0), "User already exists");

        users[msg.sender] = User(msg.sender, _username, 0);
        userAddresses.push(msg.sender);
        // Store the index (which is the new length - 1)
        userIndex[msg.sender] = userAddresses.length - 1;

        emit UserRegistered(msg.sender, _username); // Emit Event
    }

    function updateXP(address _user, uint _xp) public onlyOwner {
        require(users[_user].wallet != address(0), "User does not exist");
        users[_user].xp = _xp;
        emit XPUpdated(_user, _xp); // Emit Event
    }

    function incrementXP(address _user, uint _xpAmount) public onlyOwner {
        User storage userToUpdate = users[_user]; // Use storage pointer for efficiency
        require(userToUpdate.wallet != address(0), "User does not exist");
        userToUpdate.xp += _xpAmount; // Default overflow check in solidity >=0.8.0
        emit XPIncremented(_user, _xpAmount, userToUpdate.xp); // Emit Event
    }

    function getUser(address _user) public view returns (User memory) {
        require(users[_user].wallet != address(0), "User does not exist");
        return users[_user];
    }

    function removeUser(address _user) public onlyOwner {
        require(users[_user].wallet != address(0), "User does not exist");

        // --- Optimized Removal using index mapping (O(1)) ---
        // 1. Get the index of the user to remove
        uint indexToRemove = userIndex[_user];

        // 2. Get the address of the last user in the array
        address lastUserAddress = userAddresses[userAddresses.length - 1];

        // 3. Move the last user's address to the position of the user being removed
        userAddresses[indexToRemove] = lastUserAddress;

        // 4. Update the index mapping for the user that was moved
        userIndex[lastUserAddress] = indexToRemove;

        // 5. Remove the last element from the array
        userAddresses.pop();

        // 6. Delete the user from the main mapping and the index mapping
        delete users[_user];
        delete userIndex[_user];
        // --- End Optimized Removal ---

        /* // --- Original Removal (O(N) in worst case) ---
        // Remove from mapping
        delete users[_user];
        // Remove from array
        for (uint i = 0; i < userAddresses.length; i++) {
            if (userAddresses[i] == _user) {
                userAddresses[i] = userAddresses[userAddresses.length - 1];
                userAddresses.pop();
                break; // Important to exit loop once found
            }
        }
        // --- End Original Removal --- */


        emit UserRemoved(_user); // Emit Event
    }

    function getUserCount() public view returns (uint) {
        return userAddresses.length;
    }

    /**
     * @notice Returns data for all registered users.
     * @dev WARNING: This function iterates over all users. If the number of users
     *      becomes very large, this function call MAY FAIL due to node RPC limits
     *      when called off-chain (e.g., from Javascript). Prefer event-based indexing.
     * @return An array containing the User struct for every registered user.
     */
    function getAllUsers() public view returns (User[] memory) {
        uint userCount = userAddresses.length;
        User[] memory allUsers = new User[](userCount);
        for (uint i = 0; i < userCount; i++) {
            // Retrieve address from array, then lookup user struct in mapping
            allUsers[i] = users[userAddresses[i]];
        }
        return allUsers;
    }

    // Optional: Getter for the user index mapping if needed (e.g., for debugging/testing)
    // function getUserIndex(address _user) public view returns (uint) {
    //     require(users[_user].wallet != address(0), "User does not exist");
    //     return userIndex[_user];
    // }
}
