// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;



contract ValidatorRegistry {

    //atlas proposed base fixes and refactor
    //TODO: hook up to ftsowhitelist
    mapping(address => uint) public nodeNumber;

    mapping(address => mapping(uint => string)) public nodeRegistry;



    event NodeRegistered(address indexed owner, string nodeID);

    event NodeDeleted(address indexed owner, string nodeID);


   
    modifier isValidNodeID(string memory nodeID) {

        nodeID = string(bytes.concat(bytes("NodeID-"),bytes(nodeID)));

        bytes20 idBytes = stringToBytes20(nodeID);

        require(bytes(nodeID).length == 40, "Invalid Node ID length");
        
        require(idBytes != 0, "Invalid Node ID");
        
        _;

    }



    modifier hasLessThanFiveNodes() {

        require(nodeNumber[msg.sender] < 5, "Owner already has 5 registered nodes");

        _;

    }

    function stringToBytes20(string memory source) internal pure returns (bytes20 result) {
        
        bytes memory tempEmptyStringTest = bytes(source);
        
        if (tempEmptyStringTest.length == 0) {
            
            return 0x0;
        }
        
        assembly {
            
            result := mload(add(source, 32))

        }
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