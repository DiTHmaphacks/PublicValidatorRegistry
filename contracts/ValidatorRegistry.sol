// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IVoterWhitelister.sol";

contract ValidatorRegistry {

    address public owner;

    //Contracts
    IVoterWhitelister private voterWhitelisterContract;

    //Errors
    string private constant ERR_ONLY_OWNER = "Only Owner can call this function";
    
    constructor(address _whitelistVoterAddress) {
        voterWhitelisterContract = IVoterWhitelister(_whitelistVoterAddress);
        owner = msg.sender;
    }


    //TODO: hook up to ftsowhitelist
    mapping(address => uint) private nodeCount;
    mapping(address => bool) private whitelistedProviders;

    Node[] private nodes;

    struct Node {
        
        address owner;
        
        string nodeID;
    }

    //Events
    event NodeRegistered(address indexed owner, string nodeID);
    event NodeDeleted(address indexed owner, string nodeID);

    //Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, ERR_ONLY_OWNER);
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

    //Store whitelisted providers on mapping
    function getWhitelistedAddresses(uint _ftsoIndex) internal {
        address[] memory _whitelistedProviders = voterWhitelisterContract.getFtsoWhitelistedPriceProviders(_ftsoIndex);
        
        for (uint256 i = 0; i < _whitelistedProviders.length; i++) {
            whitelistedProviders[_whitelistedProviders[i]] = true;
        }
    }

    function registerNode(string memory nodeID) external isValidNodeID(nodeID) hasLessThanFiveNodes {
         getWhitelistedAddresses(1);

        // ensure msg.sender is whitelisted for the specified FTSO index
        require(whitelistedProviders[msg.sender], "Sender is not whitelisted for the specified FTSO index");

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

    //Change owner
    function transferOwnership(address payable _newOwner) external onlyOwner {
        owner = _newOwner;
    }

}
