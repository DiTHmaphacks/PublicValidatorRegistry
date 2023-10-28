// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IPriceSubmitter.sol";

contract FTSOProviderAndValidatorRegistry {

    address public owner;

    //Contracts
    IPriceSubmitter private priceSubmitterContract;

    //Mappings
    mapping(address => uint) public nodeCount;
    mapping(address => mapping(uint => string)) public nodeidRegistry;
    mapping(address => uint) public providerID;

    Provider[] private providers;

    constructor(address _priceSubmitterAddress) {
        priceSubmitterContract = IPriceSubmitter(_priceSubmitterAddress);
        owner = msg.sender;
    }

    //Errors
    string private constant ERR_ONLY_OWNER = "Only Owner can call this function";
    string private constant ERR_FIVE_NODE_NUMBER = "Provider already has 5 registered nodes, delete a nodeID";
    string private constant ERR_ZERO_NODE_NUMBER = "Provider doesnt have a node registered";
    string private constant ERR_NOT_WHITELISTED = "Address not Whitelisted";
    string private constant ERR_INVALID_NODEID = "Invalid Node ID";
    string private constant ERR_INVALID_NODEID_LENGTH = "Invalid Node ID length, make sure to submit with NodeID- prefix";
    string private constant ERR_ADDRESS_REGISTERED = "Address already registered, delete before registering";
    string private constant ERR_ADDRESS_NOT_REGISTERED = "Address not registered";
    
    //Events
    event ProviderRegistered(address indexed owner, string name, string url, string logo);
    event ProviderDeleted(address indexed owner);
    event NodeRegistered(address indexed owner, string nodeID);
    event NodeDeleted(address indexed owner, string nodeID);

    //Structures
    struct Provider {
        address owner;
        string Name;
        string url;
        string ipfshash;
    }

    //Modifiers

    // Check that only owner can call
    modifier onlyOwner() {
        require(msg.sender == owner, ERR_ONLY_OWNER);
        _;
    }

    // Check the nodeID is valid
    modifier isValidNodeID(string memory _nodeID) {
        require(bytes(_nodeID).length == 40, ERR_INVALID_NODEID_LENGTH);
        bytes20 idBytes = stringToBytes20(_nodeID);
        require(idBytes != 0, ERR_INVALID_NODEID);
        _;
    }

    // Check the address has less than 5 nodes registered
    modifier hasLessThanFiveNodes() {
        require(nodeCount[msg.sender] < 5, ERR_FIVE_NODE_NUMBER);
        _;
    }
    // Check the address has at least 1 node registered
    modifier hasNodeRegistered(){
        require(nodeCount[msg.sender] > 1,ERR_ZERO_NODE_NUMBER);
        _;
    }
    // Check the address is whitelisted
    modifier isWhitelisted(){
        require(priceSubmitterContract.voterWhitelistBitmap(msg.sender) > 0, ERR_NOT_WHITELISTED);
        _;
    }

    // Check address is registered
    modifier notRegistered(){
        require(providerID[msg.sender] > 0,ERR_ADDRESS_REGISTERED);
        _;
    }

    // Check address is not registered
    modifier isRegistered(){
        require(providerID[msg.sender] == 0,ERR_ADDRESS_NOT_REGISTERED);
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

    // First Time register for info
    function registerProviderInformation(string memory _name,string memory _url, string memory _logo) external isWhitelisted notRegistered {

        // checks passed, register node
        Provider memory newProvider = Provider(msg.sender, _name, _url, _logo);
        providers.push(newProvider);
        providerID[msg.sender] = providers.length;

        emit ProviderRegistered(msg.sender, _name, _url, _logo);
    }
    
    // Checks the provider is registered and then swaps last index with providers and deletes it
    function deleteProviderInformation() external isRegistered{

        uint indexToDelete = providerID[msg.sender] - 1;
        uint lastIndex = providers.length - 1;

        if (indexToDelete != lastIndex) {
            providers[indexToDelete] = providers[lastIndex];
        }
        providers.pop();
        providerID[msg.sender] = 0;

        emit ProviderDeleted(msg.sender);
    }

    // Register nodeID to address and increase the node count
    function nodeIDRegister(string memory _nodeID) external isValidNodeID(_nodeID) hasLessThanFiveNodes isWhitelisted() {
        nodeidRegistry[msg.sender][nodeCount[msg.sender]++] = _nodeID;

        emit NodeRegistered(msg.sender, _nodeID);
    }

    // Delete the NodeID and reduce Count
    function deleteNodeID(string memory _nodeID) external isValidNodeID(_nodeID) hasNodeRegistered{
        
        for (uint i = 0; i < nodeCount[msg.sender]; i++) {
          
            if (keccak256(bytes(nodeidRegistry[msg.sender][i])) == keccak256(bytes(_nodeID))) {
                delete nodeidRegistry[msg.sender][i];
                nodeCount[msg.sender]--;

                emit NodeDeleted(msg.sender, _nodeID);
                return;
            }
        }
        revert("Node not found for the owner");
    }

    // Change owner
    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }
    
}
