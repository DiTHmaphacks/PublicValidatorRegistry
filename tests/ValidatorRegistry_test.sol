// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "remix_tests.sol";
import "../contracts/ValidatorRegistry.sol";

contract ValidatorRegistryTest {

    ValidatorRegistry validatorRegistry;

    function beforeAll() public {
        validatorRegistry = new ValidatorRegistry();
    }

    function generateRandomString(uint length) internal pure returns (string memory) {
        bytes memory characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
        bytes memory randomString = new bytes(length);
        for (uint i = 0; i < length; i++) {
            uint256 index = uint256(keccak256(abi.encodePacked(i))) % characters.length;
            randomString[i] = characters[index];
        }
        return string(randomString);
    }

    function testRegisterNode() public {
            string memory nodeID = generateRandomString(32);
            validatorRegistry.registerNode(nodeID);
            (address[] memory owners, string[] memory nodeIDs) = validatorRegistry.getAllAddresses();
            
            Assert.equal(owners.length, 1, "Incorrect number of owners");
            Assert.equal(nodeIDs.length, 1, "Incorrect number of nodeIDs");
            Assert.equal(owners[0], address(this), "Incorrect owner address");
            Assert.equal(nodeIDs[0], nodeID, "Incorrect nodeID");
        }

    function testModifyNode() public {
        string memory oldNodeID = generateRandomString(32);
        string memory newNodeID = generateRandomString(33);
        validatorRegistry.registerNode(oldNodeID);
        validatorRegistry.modifyNode(oldNodeID, newNodeID);
        (address[] memory owners, string[] memory nodeIDs) = validatorRegistry.getAllAddresses();
        Assert.equal(owners.length, 2, "Incorrect number of validators after modification");
        Assert.equal(bytes(nodeIDs[0]).length, bytes(newNodeID).length, "Incorrect nodeID length after modification");
    }

    function testDeleteNode() public {
        string memory nodeID = generateRandomString(33);
        validatorRegistry.registerNode(nodeID);
        validatorRegistry.deleteNode(nodeID);
        (address[] memory owners,) = validatorRegistry.getAllAddresses();
        Assert.equal(owners.length, 2, "Node not deleted successfully");
    }


    function testGetAllValidators() public {
        string memory nodeID1 = generateRandomString(32);
        string memory nodeID2 = generateRandomString(33);
        validatorRegistry.registerNode(nodeID1);
        validatorRegistry.registerNode(nodeID2);

        (address[] memory owners, string[] memory nodeIDs) = validatorRegistry.getAllAddresses();
        Assert.equal(owners.length, 4, "Incorrect number of rows returned");
    }
}