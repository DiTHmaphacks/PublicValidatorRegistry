// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;



contract ValidatorRegistry {

    //to be reviewed
    //atlas proposed base fixes and refactor
    //TODO: hook up to ftsowhitelist
    mapping(address => uint) public nodeNumber;

    mapping(address => mapping(uint => string)) public nodeRegistry;



    event NodeRegistered(address indexed owner, string nodeID);

    event NodeDeleted(address indexed owner, string nodeID);


   
    modifier isValidNodeID(string memory nodeID) {
        //TODO: bytes20
        require(bytes(nodeID).length >= 32 && bytes(nodeID).length <= 33, "Invalid Node ID length");

        _;

    }



    modifier hasLessThanFiveNodes() {

        require(nodeNumber[msg.sender] < 5, "Owner already has 5 registered nodes");

        _;

    }



    function registerNode(string memory nodeID) external isValidNodeID(nodeID) hasLessThanFiveNodes {

        nodeRegistry[msg.sender][nodeNumber[msg.sender]] = nodeID;

        nodeNumber[msg.sender]++;

        emit NodeRegistered(msg.sender, nodeID);

    }



    function deleteNode(string memory nodeID) external isValidNodeID(nodeID) {

        uint totalNumberOfNodes = nodeNumber[msg.sender];

        bool nodeFound = false;



        for (uint i = 0; i < totalNumberOfNodes; i++) {

            if (keccak256(abi.encodePacked(nodeRegistry[msg.sender][i])) == keccak256(abi.encodePacked(nodeID))) {

                nodeFound = true;

                if (i < totalNumberOfNodes - 1) {

                    nodeRegistry[msg.sender][i] = nodeRegistry[msg.sender][totalNumberOfNodes - 1];

                }

                delete nodeRegistry[msg.sender][totalNumberOfNodes - 1];

                nodeNumber[msg.sender]--;

                emit NodeDeleted(msg.sender, nodeID);

                break;

            }

        }

        require(nodeFound, "Node not found for the owner");

    }

}