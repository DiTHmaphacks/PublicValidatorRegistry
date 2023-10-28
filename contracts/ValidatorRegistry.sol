// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface WhitelistVoter {
    function getFtsoWhitelistedPriceProviders(uint256 _ftsoIndex) external view returns (address[] memory);
}

contract ValidatorRegistry is WhitelistVoter {

    address public owner;
    address public whitelistVoterAddress;
    WhitelistVoter public whitelistVoter;

    constructor(address _whitelistVoterAddress) {
        whitelistVoterAddress = _whitelistVoterAddress;
        whitelistVoter = WhitelistVoter(_whitelistVoterAddress);
        owner = msg.sender;
        totalModerators = 0;
    }
    
    //Errors
    string private constant ERR_ONLY_OWNER = "Only Owner can call this function";

    string private constant ERR_ONLY_MOD = "Only moderators can call this function";
    
    mapping(address => uint) public nodeCount;

    mapping(address => bool) private moderators;

    mapping(address => bool) private blacklist;

    mapping(address => mapping(address => bool)) private votes;

    mapping(address => uint256) private totalVotes;

    uint256 private totalModerators;

    Node[] private nodes;

    struct Node {
        
        address owner;
        
        string nodeID;
    }

    event NodeRegistered(address indexed owner, string nodeID);

    event NodeDeleted(address indexed owner, string nodeID);

    //Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, ERR_ONLY_OWNER);
        _;
    }

    modifier onlyModerator() {
        require(moderators[msg.sender], ERR_ONLY_MOD);
        _;
    }
   
    modifier isValidNodeID(string memory nodeID) {

        //CoNH4gyEwB9gTrEmozwh14Zr8hs6wokRS

        require(!isNodeIDUsed(nodeID), "Node ID already registered"); // verify if nodeid is already used

        nodeID = string(bytes.concat(bytes("NodeID-"),bytes(nodeID)));

        bytes20 idBytes = stringToBytes20(nodeID);

        require(bytes(nodeID).length == 40, "Invalid Node ID length");
        
        require(idBytes != 0, "Invalid Node ID");
        
        _;

    }


    modifier hasLessThanFiveNodes() {

        require(nodeCount[msg.sender] < 5, "Owner already has 5 registered nodes");

        _;

    }

    function getFtsoWhitelistedPriceProviders(uint256 _ftsoIndex) external view returns (address[] memory) {

        address[] memory whitelistedProviders = WhitelistVoter(whitelistVoterAddress).getFtsoWhitelistedPriceProviders(_ftsoIndex);
        
        // check if msg.sender is in the whitelisted providers array
        bool senderIsWhitelisted = false;

        for (uint256 i = 0; i < whitelistedProviders.length; i++) {
            
            if (whitelistedProviders[i] == msg.sender) {
                
                senderIsWhitelisted = true;
                
                break;
            
            }
        
        }

        require(senderIsWhitelisted, "Sender is not whitelisted for the specified FTSO index");

        return whitelistedProviders;

    }


    function stringToBytes20(string memory source) internal pure returns (bytes20 result) {
        
        //lightftso avax reference: https://docs.avax.network/reference/standards/cryptographic-primitives#tls-addresses

        bytes memory tempEmptyStringTest = bytes(source); 
        
        if (tempEmptyStringTest.length == 0) {
            
            return 0x0;
        }
        
        assembly {
            
            result := mload(add(source, 32))

        }

    }


    function isNodeIDUsed(string memory nodeID) internal view returns (bool) {
            
        for (uint i = 0; i < nodes.length; i++) {
                   
             if (keccak256(bytes(nodes[i].nodeID)) == keccak256(bytes(nodeID))) {
                        
                return true;
                    
            }

        }
            
        return false;

    }


    function registerNode(string memory nodeID, uint256 ftsoWhitelistIndex) external isValidNodeID(nodeID) hasLessThanFiveNodes {
         
        address[] memory whitelistedProviders = whitelistVoter.getFtsoWhitelistedPriceProviders(ftsoWhitelistIndex); //user defined index instead of hardcode

        bool senderIsWhitelisted = false;
        
        for (uint256 i = 0; i < whitelistedProviders.length; i++) {
            
            if (whitelistedProviders[i] == msg.sender) {
            
                senderIsWhitelisted = true;
            
                break;
            
            }
        
        }

        // ensure msg.sender is whitelisted for the specified FTSO index
        require(senderIsWhitelisted, "Sender is not whitelisted for the specified FTSO index");

        // checks passed, register node
        Node memory newNode = Node(msg.sender, nodeID);
        
        nodes.push(newNode);
        
        nodeCount[msg.sender]++;
        
        emit NodeRegistered(msg.sender, nodeID);
        
    }



    function deleteNode(string memory nodeID) external { //skip nodeid validation due to unique check, only check if msg.sender is owner
        
        for (uint i = 0; i < nodes.length; i++) {
          
            if (keccak256(bytes(nodes[i].nodeID)) == keccak256(bytes(nodeID)) && nodes[i].owner == msg.sender) {
          
                emit NodeDeleted(msg.sender, nodeID);
          
                nodes[i] = nodes[nodes.length - 1];
          
                nodes.pop(); //now a dynamic array so need to pop it
          
                return;
            }

        }

        revert("Node not found for the owner");
    }


    function getAllOwnersAndNodes() external view returns (address[] memory owners, string[] memory nodeIDs) {
        
        owners = new address[](nodes.length);
        
        nodeIDs = new string[](nodes.length);

        for (uint i = 0; i < nodes.length; i++) {
            
            owners[i] = nodes[i].owner;
            
            nodeIDs[i] = nodes[i].nodeID;
        
        }

        return (owners, nodeIDs);

    }

    // Only owner can add moderators
     function addModerator(address _moderator) external onlyOwner {
        require(!moderators[_moderator], "Address is already a moderator");
        moderators[_moderator] = true;
        totalModerators++;

        //testing addy's
        //0x278F11EEEe212a796C750f03382Ddb0970F7A631
        //0x30339DFfD7953259e6Ae934c285F9d3179b110D6
    }

    function removeModerator(address _moderator) external onlyOwner {
        require(moderators[_moderator], "Address is not a moderator");
        moderators[_moderator] = false;
        totalModerators--;
    }

     function isModerator(address _address) external view returns (bool) {
        return moderators[_address];
    }

    // blacklist an addy (requires majority vote from mods)
     function modBlacklist(address _address) external onlyModerator {
        require(!votes[_address][msg.sender], "You have already voted on this proposal");

        votes[_address][msg.sender] = true;
        totalVotes[_address]++;

        // majority, blacklist the address
        if (totalVotes[_address] > totalModerators / 2) {
            blacklist[_address] = true;
        }
    }

    // unblacklist an addy, with majority
    function modUnblacklist(address _address) external onlyModerator {
        require(!votes[_address][msg.sender], "You have already voted on this proposal");

        votes[_address][msg.sender] = true;
        totalVotes[_address]++;

        // majority, unblacklist the address
        if (totalVotes[_address] > totalModerators / 2) {
            blacklist[_address] = false;
        }
    }

    // check if an addy is blacklisted
    function isBlacklisted(address _address) external view returns (bool) {
        return blacklist[_address];
    }

    //Change owner
    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

}