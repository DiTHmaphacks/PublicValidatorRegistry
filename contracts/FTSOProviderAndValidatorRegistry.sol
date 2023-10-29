// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IPriceSubmitter.sol";

contract FTSOProviderAndValidatorRegistry {

    address public owner;

    //Contracts
    IPriceSubmitter private priceSubmitterContract;

    //Mappings
    mapping(address => uint) private nodeCount;
    mapping(address => mapping(uint => string)) private nodeidRegistry;
    mapping(address => uint) private providerID;

    Provider[] private providers;

    constructor(address _priceSubmitterAddress) {
        priceSubmitterContract = IPriceSubmitter(_priceSubmitterAddress);
        owner = msg.sender;
    }

    //Errors
    string private constant ERR_ONLY_OWNER = "Only Owner can call this function";
    string private constant ERR_FIVE_NODE_NUMBER = "Provider already has 5 registered nodes, delete a nodeID";
    string private constant ERR_NODE_REGISTERED = "Provider has a node registered, delete nodes to continue";
    string private constant ERR_ZERO_NODE_NUMBER = "Provider doesnt have a node registered";
    string private constant ERR_NOT_WHITELISTED = "Address not Whitelisted";
    string private constant ERR_INVALID_NODEID = "Invalid Node ID";
    string private constant ERR_INVALID_NODEID_LENGTH = "Invalid Node ID length, make sure to submit with NodeID- prefix";
    string private constant ERR_ADDRESS_REGISTERED = "Address already registered, use modify or delete before trying again";
    string private constant ERR_ADDRESS_NOT_REGISTERED = "Address not registered, register a provider first";
    string private constant ERR_NAME_LENGTH = "Name length is restricted it up to 20 characters";
    
    //Events
    event ProviderRegistered(address indexed owner, string name, string url, string logo);
    event ProviderDeleted(address indexed owner);
    event ProviderModified(address indexed owner, string name, string url, string logo);
    event NodeRegistered(address indexed owner, string nodeID);
    event NodeDeleted(address indexed owner, string nodeID);
    event AllNodesDeleted(address indexed owner);

    //Structures
    // Name restricted to 20chars, logoipfshash needs to be the ipfs hash of the logo :)
    struct Provider {
        address owner;
        string Name;
        string url;
        string logoipfshash;
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
    modifier hasNodeRegistered(address _providerAddress){
        require(nodeCount[_providerAddress] > 0, ERR_ZERO_NODE_NUMBER);
        _;
    }

    // Check the address has at least 1 node registered
    modifier doesNotHaveNodeRegistered(){
        require(nodeCount[msg.sender] == 0, ERR_NODE_REGISTERED);
        _;
    }

    // Check the address is whitelisted
    modifier isWhitelisted(){
        require(priceSubmitterContract.voterWhitelistBitmap(msg.sender) > 0, ERR_NOT_WHITELISTED);
        _;
    }

    // Check address is registered
    modifier isRegistered(address _providerAddress){
        require(providerID[_providerAddress] > 0, ERR_ADDRESS_NOT_REGISTERED);
        _;
    }

    // Check address is not registered
    modifier notRegistered(){
        require(providerID[msg.sender] == 0, ERR_ADDRESS_REGISTERED);
        _;
    }

    // Check name is below 20 characters
    modifier nameIsUnder20chars(string calldata _name) {
        require(bytes(_name).length <= 20, ERR_NAME_LENGTH);
        _;
    }

    // Functions
    function stringToBytes20(string memory source) internal pure returns (bytes20 result) {

        bytes memory tempEmptyStringTest = bytes(source); 
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        
        assembly {
            result := mload(add(source, 32))
        }
    }

    // First Time register for provider information
    function registerProviderInformation(string calldata _name,string calldata _url, string calldata _logoipfshash) external  isWhitelisted notRegistered nameIsUnder20chars(_name){

        Provider memory newProvider = Provider(msg.sender, _name, _url, _logoipfshash);
        providers.push(newProvider);
        providerID[msg.sender] = providers.length;

        emit ProviderRegistered(msg.sender, _name, _url, _logoipfshash);
    }
    
    // Modify existing provider information
    function modifyProviderInformation(string calldata _name,string calldata _url, string calldata _logoipfshash) external  isRegistered(msg.sender) nameIsUnder20chars(_name){

        Provider storage provider = providers[providerID[msg.sender] - 1];
        provider.Name = _name;
        provider.url = _url;
        provider.logoipfshash = _logoipfshash;

        emit ProviderModified(msg.sender, _name, _url, _logoipfshash);
    }

    // Checks the provider is registered and then swaps last index with providers and deletes it
    function deleteProviderInformation() external isRegistered(msg.sender) doesNotHaveNodeRegistered{

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
    function nodeIDRegister(string calldata _nodeID) external isRegistered(msg.sender) hasLessThanFiveNodes isValidNodeID(_nodeID) {

        nodeidRegistry[msg.sender][nodeCount[msg.sender]++] = _nodeID;

        emit NodeRegistered(msg.sender, _nodeID);
    }

    // Delete the NodeID and reduce Count
    function deleteNodeID(string calldata _nodeID) external hasNodeRegistered(msg.sender) isValidNodeID(_nodeID) {
        
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

    // Delete all NodeIDs and reset count
    function deleteAllNodeIDs() external hasNodeRegistered(msg.sender){
        for (uint i = 0; i < nodeCount[msg.sender]; i++){
            delete nodeidRegistry[msg.sender][i];
        }
        delete nodeCount[msg.sender];

        emit AllNodesDeleted(msg.sender);
    }

    // Return provider information for the address
    function getProviderInformation(address _providerAddress) external view isRegistered(_providerAddress) returns(string memory, string memory, string memory) {

        Provider storage provider = providers[providerID[_providerAddress] - 1];

        return (provider.Name,provider.url,provider.logoipfshash);
    }
    
    // Return all nodeIDS of address
    function getNodeIDs(address _providerAddress) external view hasNodeRegistered(_providerAddress) returns(string[] memory){

        string[] memory _nodeIDs = new string[](nodeCount[_providerAddress]);

        for (uint i = 0; i < nodeCount[_providerAddress]; i++){
            _nodeIDs[i] = nodeidRegistry[_providerAddress][i];
        }

        return _nodeIDs;
    }

    // Return 2 arrays addresses and their corresponding information in json format
    function getAllDataJson() external view returns (address[] memory, string[] memory) {

        address[] memory _addresses = new address[](providers.length);
        string[] memory _information = new string[](providers.length);
        
        for (uint i = 0; i < providers.length; i++) {

            Provider storage provider = providers[i];
            _addresses[i] = provider.owner;
            string[] memory _nodeIDs = new string[](nodeCount[provider.owner]);
            for(uint j = 0; j < nodeCount[provider.owner]; j++){
                _nodeIDs[j] = nodeidRegistry[provider.owner][j];
            }

            string memory nodeIDs = stringifyArray(_nodeIDs);
            string memory jsonString = string(abi.encodePacked(
                '{"name":"', 
                provider.Name, 
                '","url":"', 
                provider.url, 
                '","logo":"', 
                provider.logoipfshash, 
                '","nodeID":', 
                nodeIDs, 
                "}"
            ));
            _information[i] = jsonString;
        }

        return (_addresses, _information);
    }

    // Change an array into a string
    function stringifyArray(string[] memory array) internal pure returns (string memory) {

        string memory result = '["';
        for (uint i = 0; i < array.length; i++) {
            result = string(abi.encodePacked(result, array[i]));
            if (i < array.length - 1) {
                result = string(abi.encodePacked(result, '","'));
            }
        }
        result = string(abi.encodePacked(result, '"]'));

        return result;
    }

    // Change owner
    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }
    
}
