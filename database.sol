// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract UserDatabase {
    struct User {
        address wallet;
        string username;
        uint xp;
    }
    
    mapping(address => User) public users;
    address[] public userAddresses;
    
    event UserRegistered(address indexed wallet, string username);
    event XPUpdated(address indexed wallet, uint newXP);
    
    // Register or update a user
    function setUser(string memory _username) external {
        if (users[msg.sender].wallet == address(0)) {
            // New user
            users[msg.sender] = User({
                wallet: msg.sender,
                username: _username,
                xp: 0
            });
            userAddresses.push(msg.sender);
            emit UserRegistered(msg.sender, _username);
        } else {
            // Existing user - update username only
            users[msg.sender].username = _username;
        }
    }
    
    // Update XP (callable by owner/dashboard)
    function updateXP(address _user, uint _xp) external {
        require(users[_user].wallet != address(0), "User not registered");
        users[_user].xp = _xp;
        emit XPUpdated(_user, _xp);
    }
    
    // Get user count
    function getUserCount() public view returns (uint) {
        return userAddresses.length;
    }
    
    // Get all users (for UI)
    function getAllUsers() public view returns (User[] memory) {
        User[] memory allUsers = new User[](userAddresses.length);
        for (uint i = 0; i < userAddresses.length; i++) {
            allUsers[i] = users[userAddresses[i]];
        }
        return allUsers;
    }
}