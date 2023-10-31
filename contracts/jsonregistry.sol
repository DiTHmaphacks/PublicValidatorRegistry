// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0 <0.9.0;

import "./IPriceSubmitter.sol";

contract FTSOandValidatorRegistry {

    address public owner;
    uint256 private totalModerators;
    string[] public providerInformation;
    uint256 public totalProvidersRegistered;

    //Contracts
    IPriceSubmitter private priceSubmitterContract;
    
    //Errors
    string private constant ERR_ONLY_OWNER = "Only Owner can call this function";
    string private constant ERR_ONLY_MOD = "Only moderators can call this function";
    string private constant ERR_ADDRESS_NOT_WHITELISTED = "Address not whitelisted";
    string private constant ERR_PROVIDER_NOT_REGISTERED = "Address not registered, user registerProviderInformation function to register";
    string private constant ERR_JSON_ZERO_LENGTH = "Requires input to not be empty";

    //Mappings
    mapping(address => uint) public providerID;
    mapping(uint => address) public idProvider;
    mapping(address => bool) public providerRegistered;
    mapping(address => bool) private moderators;
    mapping(address => bool) private blacklist;
    mapping(address => mapping(address => bool)) private votes;
    mapping(address => uint256) private totalVotes;

    constructor(address _priceSubmitterAddress) {
        priceSubmitterContract = IPriceSubmitter(_priceSubmitterAddress);
        owner = msg.sender;
        totalModerators = 0;
    }

    //Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, ERR_ONLY_OWNER);
        _;
    }

    modifier onlyModerator() {
        require(moderators[msg.sender], ERR_ONLY_MOD);
        _;
    }

    modifier isWhitelisted(){
        require(priceSubmitterContract.voterWhitelistBitmap(msg.sender) > 0,ERR_ADDRESS_NOT_WHITELISTED);
        _;
    }

    //Events
    event ProviderRegistered(address indexed owner);
    event ProviderDeleted(address indexed owner);

    // Functions
    // Register provider information. String input needs to be a json formatted string
    // with fields address, name , NodeID , url , logourl
    function registerProviderInformation(string calldata _jsonProviderInformation) isWhitelisted external{

        if (providerRegistered[msg.sender]){
            providerInformation[providerID[msg.sender]] = _jsonProviderInformation;
        }
        else{
            providerRegistered[msg.sender] = true;
            providerID[msg.sender] = ++totalProvidersRegistered;
            idProvider[providerID[msg.sender]] = msg.sender;
            providerInformation.push(_jsonProviderInformation);
        }

        emit ProviderRegistered(msg.sender);
    }

    //Delete provider information
    function deleteProviderInformation() external{

        require(providerRegistered[msg.sender],ERR_PROVIDER_NOT_REGISTERED);

        uint256 providerToDelete = providerID[msg.sender];
        uint256 lastIndex = totalProvidersRegistered;

        providerInformation[providerToDelete- 1] = providerInformation[lastIndex - 1];
        providerID[idProvider[lastIndex]] = providerID[msg.sender];
        idProvider[providerID[msg.sender]] = idProvider[lastIndex];

        providerInformation.pop();        
        delete idProvider[lastIndex];
        delete providerID[msg.sender];
        delete providerRegistered[msg.sender];
        totalProvidersRegistered--;
        
        emit ProviderDeleted(msg.sender);
    }

    // Return all strings in array
    function getAllProviderInformation() external view returns(string[] memory){

        return providerInformation;
    }

}
