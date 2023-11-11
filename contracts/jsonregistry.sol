// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0 < 0.8.11;

import "../ftso/userInterfaces/IPriceSubmitter.sol";

contract ftso2ValidatorRegistry {

    address public owner;
    string[] private providerInformation;
    uint256 private totalProvidersRegistered;
    uint256 private totalModerators;
    uint256 private voteThreshold;
    uint256 public stringLengthCap;

    //Contracts
    IPriceSubmitter private priceSubmitterContract;
    
    //Errors
    string private constant ERR_ONLY_OWNER = "Only Owner can call this function";
    string private constant ERR_ONLY_MOD = "Only moderators can call this function";
    string private constant ERR_ADDRESS_NOT_WHITELISTED = "Address not whitelisted";
    string private constant ERR_PROVIDER_NOT_REGISTERED = "Address not registered, user registerProviderInformation function to register";
    string private constant ERR_JSON_ZERO_LENGTH = "Requires input to not be empty";
    string private constant ERR_JSON_INPUT_TOO_LONG = "Input string too long";
    string private constant ERR_ADDRESS_BLACKLISTED = "Address is blacklisted";
    string private constant ERR_ALLREADY_VOTED = "Moderator has already voted for this address";
    string private constant ERR_SAME_VOTE = "Moderator has already voted the same for this address";
    string private constant ERR_SAME_MODERATOR_STATUS = "Moderator has the same status owner is trying to set";
    string private constant ERR_INVALID_PROVIDER_ID = "Invalid Provider ID";

    //Mappings
    mapping(address => uint) private  providerID;
    mapping(uint => address) private  idProvider;
    mapping(address => bool) private providerRegistered;
    mapping(address => bool) private moderators;
    mapping(address => bool) private blacklist;
    mapping(address => mapping(address => bool)) private blacklistModeratorVotes;
    mapping(address => mapping(address => bool)) private informationModeratorVotes;
    mapping(address => uint) private numberBlacklistModeratorVotes;
    mapping(address => uint) private numberInformationModeratorVotes;

    constructor(address _priceSubmitterAddress){
        priceSubmitterContract = IPriceSubmitter(_priceSubmitterAddress);
        owner = msg.sender;
        totalModerators = 0;
        stringLengthCap = 255;
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
        require(priceSubmitterContract.voterWhitelistBitmap(msg.sender) > 0, ERR_ADDRESS_NOT_WHITELISTED);
        _;
    }

    modifier notBlacklisted(){
        require(!blacklist[msg.sender],ERR_ADDRESS_BLACKLISTED);
        _;
    }

    modifier differentBlacklistVote(address _blacklistAddress,bool _vote){
        require (blacklistModeratorVotes[msg.sender][_blacklistAddress] != _vote, ERR_SAME_VOTE);
        _;
    }

    modifier differentInformationVote(address _addressToDelete,bool _vote){
        require (informationModeratorVotes[msg.sender][_addressToDelete] != _vote, ERR_SAME_VOTE);
        _;
    }
    
    //Events
    event ProviderRegistered(address indexed owner);
    event ProviderDeleted(address indexed owner);
    event BlacklistedStatusChanged(address indexed blacklistedAddress,bool status);
    event ProviderInformationModerated(address indexed providerAddress);
    event ModeratorStatusChanged(address indexed moderator,bool status);
    event OwnershipChanged(address indexed owner);
    event StringLengthChanged(uint stringLength);

    // Functions
    // Register provider information. String input needs to be a json formatted string
    // with fields address, name , NodeID , url , logourl
    function registerProviderInformation(string calldata _jsonProviderInformation) isWhitelisted notBlacklisted external{

        require(bytes(_jsonProviderInformation).length < stringLengthCap, ERR_JSON_INPUT_TOO_LONG);
        if (providerRegistered[msg.sender]){
            require(providerID[msg.sender] >= 0 && providerID[msg.sender] <= providerInformation.length, ERR_INVALID_PROVIDER_ID);
            providerInformation[providerID[msg.sender]] = _jsonProviderInformation;
        }
        else{
            providerRegistered[msg.sender] = true;
            providerID[msg.sender] = totalProvidersRegistered++;
            idProvider[providerID[msg.sender]] = msg.sender;
            providerInformation.push(_jsonProviderInformation);
        }

        emit ProviderRegistered(msg.sender);
    }

    //Delete provider information
    function deleteProviderInformation() isWhitelisted notBlacklisted external{

        require(providerRegistered[msg.sender],ERR_PROVIDER_NOT_REGISTERED);

        uint256 providerToDelete = providerID[msg.sender];
        uint256 lastIndex = totalProvidersRegistered;

        if (providerToDelete != lastIndex - 1) {
            providerInformation[providerToDelete] = providerInformation[lastIndex - 1];
            providerID[idProvider[lastIndex - 1]] = providerID[msg.sender];
            idProvider[providerID[msg.sender]] = idProvider[lastIndex - 1];
        }

        providerInformation.pop();        
        delete idProvider[lastIndex - 1];
        delete providerID[msg.sender];
        delete providerRegistered[msg.sender];
        totalProvidersRegistered--;
        
        emit ProviderDeleted(msg.sender);
    }

    // Return all strings in array
    function getAllProviderInformation() external view returns(string[] memory){

        return providerInformation;
    }

    // Blacklist address when votes pass 50% of total votes threshold, moderators can recall the function to change their vote
    function blacklistAddress(address _blacklistAddress, bool _vote) external onlyModerator differentBlacklistVote(_blacklistAddress,_vote){
        
        blacklistModeratorVotes[msg.sender][_blacklistAddress] = _vote;
        if (_vote){
            ++numberBlacklistModeratorVotes[_blacklistAddress];
            if (numberBlacklistModeratorVotes[_blacklistAddress] > voteThreshold) {
            blacklist[_blacklistAddress] = true;
        }
        }
        else{
            assert(numberBlacklistModeratorVotes[_blacklistAddress] > 0);
            --numberBlacklistModeratorVotes[_blacklistAddress];
            if (numberBlacklistModeratorVotes[_blacklistAddress] <= voteThreshold) {
            blacklist[_blacklistAddress] = false;
            }
        }

        emit BlacklistedStatusChanged(_blacklistAddress,blacklist[_blacklistAddress]);
    }

    // Delete provider information when votes pass 50% of total votes threshold, moderators can recall the function to change their vote
    function moderatorDeleteProviderInformation(address _addressToDelete, bool _vote) external onlyModerator differentInformationVote(_addressToDelete,_vote){
        
        require(providerRegistered[_addressToDelete],ERR_PROVIDER_NOT_REGISTERED);
        informationModeratorVotes[msg.sender][_addressToDelete] = _vote;
        if(_vote){
            ++numberInformationModeratorVotes[_addressToDelete];
            if (numberInformationModeratorVotes[_addressToDelete] > voteThreshold){

                uint256 providerToDelete = providerID[_addressToDelete];
                uint256 lastIndex = totalProvidersRegistered;

                if (providerToDelete != lastIndex - 1) {
                    providerInformation[providerToDelete] = providerInformation[lastIndex - 1];
                    providerID[idProvider[lastIndex - 1]] = providerID[_addressToDelete];
                    idProvider[providerID[_addressToDelete]] = idProvider[lastIndex - 1];
                }

                providerInformation.pop();        
                delete idProvider[lastIndex - 1];
                delete providerID[_addressToDelete];
                delete providerRegistered[_addressToDelete];
                totalProvidersRegistered--;
            }
        }
        else{
            assert(numberInformationModeratorVotes[_addressToDelete] > 0);
            --numberInformationModeratorVotes[_addressToDelete];
        }

        emit ProviderInformationModerated(_addressToDelete);
    }

    // Add moderators, only owner can add moderators
    function changeModeratorStatus(address _moderator, bool _status) external onlyOwner{
        
        require(moderators[_moderator] != _status, ERR_SAME_MODERATOR_STATUS);
        moderators[_moderator] = _status;
        if (_status){
            ++totalModerators;
        }
        else{
            assert(totalModerators > 0);
            --totalModerators;
        }
        voteThreshold = totalModerators / 2 + 1;

        emit ModeratorStatusChanged(_moderator,_status);
    }
    // Change owner
    function transferOwnership(address _newOwner) external onlyOwner{
        owner = _newOwner;
        emit OwnershipChanged(_newOwner);
    }
    // Change string length cap in case of further fields added
    function changeStringLengthCap(uint _newLength) external onlyOwner{
        stringLengthCap = _newLength;
        emit StringLengthChanged(_newLength);
    }
}
