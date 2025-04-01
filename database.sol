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
  
    function setUser(string memory _username) external {
        if (users[msg.sender].wallet == address(0)) {
            users[msg.sender] = User({
                wallet: msg.sender,
                username: _username,
                xp: 0
            });
            userAddresses.push(msg.sender);
            emit UserRegistered(msg.sender, _username);
        } else {
            users[msg.sender].username = _username;
        }
    }
  
    function updateXP(address _user, uint _xp) external {
        require(users[_user].wallet != address(0), "User not registered");
        users[_user].xp = _xp;
        emit XPUpdated(_user, _xp);
    }
    
    function getUserCount() public view returns (uint) {
        return userAddresses.length;
    }

    function getAllUsers() public view returns (User[] memory) {
        User[] memory allUsers = new User[](userAddresses.length);
        for (uint i = 0; i < userAddresses.length; i++) {
            allUsers[i] = users[userAddresses[i]];
        }
        return allUsers;
    }
}
