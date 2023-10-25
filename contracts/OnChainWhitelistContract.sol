// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//ripped from https://www.freecodecamp.org/news/how-to-implement-whitelist-in-smartcontracts-erc-721-nft-erc-1155-and-others/

import "./Ownable.sol"; // Import the Ownable contract here

contract OnChainWhitelistContract is Ownable {

    mapping(address => bool) public whitelist;

    /**
     * @notice Add to whitelist
     */
    function addToWhitelist(address[] calldata toAddAddresses) external onlyOwner {
        for (uint i = 0; i < toAddAddresses.length; i++) {
            whitelist[toAddAddresses[i]] = true;
        }
    }

    /**
     * @notice Remove from whitelist
     */
    function removeFromWhitelist(address[] calldata toRemoveAddresses) external onlyOwner {
        for (uint i = 0; i < toRemoveAddresses.length; i++) {
            delete whitelist[toRemoveAddresses[i]];
        }
    }

    /**
     * @notice Function with whitelist
     */
    function getFtsoWhitelistedPriceProviders() external view returns (address[] memory) {
        require(whitelist[msg.sender], "NOT_IN_WHITELIST");

        // Example implementation: return an array with a single whitelisted address
        address[] memory providers = new address[](0);
        providers[0] = msg.sender;
        return providers;
    }
}
