// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OnChainWhitelistContract {
    function getFtsoWhitelistedPriceProviders() external view returns (address[] memory);
}

contract ValidatorRegistry {
    struct NodeInfo {
        address owner;
        string nodeID;
    }

    mapping(address => NodeInfo[]) private nodeRegistry;

    address public voterWhitelisterAddress;
    OnChainWhitelistContract public whitelistContract;

    event NodeRegistered(address indexed owner, string nodeID);
    event NodeModified(address indexed owner, string oldNodeID, string newNodeID);
    event NodeDeleted(address indexed owner, string nodeID);

        constructor(address _whitelistContractAddress) {
        whitelistContract = OnChainWhitelistContract(_whitelistContractAddress);
    }

 /*   constructor(address _voterWhitelisterAddress) {
        voterWhitelisterAddress = _voterWhitelisterAddress;
    }*/


    modifier isValidNodeID(string memory nodeID) {
        require(bytes(nodeID).length > 32 && bytes(nodeID).length <= 33, "Invalid Node ID length");
        _;
    }

    modifier hasLessThanFiveNodes() {
        require(nodeRegistry[msg.sender].length < 5, "Owner already has 5 registered nodes");
        _;
    }

    modifier isWhitelisted() {
        require(isAddressWhitelisted(msg.sender), "Sender is not whitelisted");
        _;
    }

    function registerNode(string memory nodeID) external isValidNodeID(nodeID) hasLessThanFiveNodes isWhitelisted {
        

        nodeRegistry[msg.sender].push(NodeInfo({
            owner: msg.sender,
            nodeID: nodeID
        }));

        emit NodeRegistered(msg.sender, nodeID);
    }

    function modifyNode(string memory oldNodeID, string memory newNodeID) external isValidNodeID(newNodeID) isWhitelisted {
        
        NodeInfo[] storage nodes = nodeRegistry[msg.sender];

        for (uint256 i = 0; i < nodes.length; i++) {
            if (keccak256(abi.encodePacked(nodes[i].nodeID)) == keccak256(abi.encodePacked(oldNodeID))) {
                nodes[i].nodeID = newNodeID;

                emit NodeModified(msg.sender, oldNodeID, newNodeID);
                return;
            }
        }

        revert("Old node ID not found for the owner");
    }

    function deleteNode(string memory nodeID) external isValidNodeID(nodeID) isWhitelisted {
        NodeInfo[] storage nodes = nodeRegistry[msg.sender];

        for (uint256 i = 0; i < nodes.length; i++) {
            if (keccak256(abi.encodePacked(nodes[i].nodeID)) == keccak256(abi.encodePacked(nodeID))) {
                
                nodes[i] = nodes[nodes.length - 1];
                
                nodes.pop(); //remove node based on match

                emit NodeDeleted(msg.sender, nodeID);
                return;
            }
        }

        revert("Node not found for the owner");
    }

    function getAllAddresses() external view returns (address[] memory allOwners, string[] memory nodeIDs) {
        uint256 totalNodes;
        for (uint256 i = 0; i < nodeRegistry[msg.sender].length; i++) {
            totalNodes += 1;
        }

        allOwners = new address[](totalNodes);
        nodeIDs = new string[](totalNodes);

        for (uint256 i = 0; i < nodeRegistry[msg.sender].length; i++) {
            allOwners[i] = nodeRegistry[msg.sender][i].owner;
            nodeIDs[i] = nodeRegistry[msg.sender][i].nodeID;
        }

        return (allOwners, nodeIDs);
    }

    function isAddressWhitelisted(address _address) private view returns (bool) {
        OnChainWhitelistContract whitelister = OnChainWhitelistContract(voterWhitelisterAddress);
        address[] memory whitelistedProviders = whitelister.getFtsoWhitelistedPriceProviders();

        for (uint256 i = 0; i < whitelistedProviders.length; i++) {
            if (whitelistedProviders[i] == _address) {
                return true;
            }
        }

        return false;
    }
}
