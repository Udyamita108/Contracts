// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract UserDatabase {
    struct User {
        address wallet;
        string username;
        uint xp;
    }

    mapping(address => User) public users;
    address[] private userAddresses;
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized: Only owner can update XP");
        _;
    }

    constructor() {
        owner = msg.sender; // Set deployer as the owner
    }

    function setUser(string memory _username) public {
        require(users[msg.sender].wallet == address(0), "User already exists");
        users[msg.sender] = User(msg.sender, _username, 0);
        userAddresses.push(msg.sender);
    }

    function updateXP(address _user, uint _xp) public onlyOwner {
        require(users[_user].wallet != address(0), "User does not exist");
        users[_user].xp = _xp;
    }

    function incrementXP(address _user, uint _xpAmount) public onlyOwner {
        require(users[_user].wallet != address(0), "User does not exist");
        users[_user].xp += _xpAmount;
    }

    function getUser(address _user) public view returns (User memory) {
        require(users[_user].wallet != address(0), "User does not exist");
        return users[_user];
    }

    function removeUser(address _user) public onlyOwner {
        require(users[_user].wallet != address(0), "User does not exist");
        
        // Remove from mapping
        delete users[_user];

        // Remove from array
        for (uint i = 0; i < userAddresses.length; i++) {
            if (userAddresses[i] == _user) {
                userAddresses[i] = userAddresses[userAddresses.length - 1];
                userAddresses.pop();
                break;
            }
        }
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
