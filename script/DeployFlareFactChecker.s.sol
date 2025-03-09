// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/FlareFactChecker.sol";

contract DeployFlareFactChecker is Script {
    function run() external {
        // Load environment variables
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Default parameters
        uint256 verificationFee = 1 wei; // Default fee
        address aggregator = address(0);      // Default aggregator
        
        // Try to load fee from environment variable
        try vm.envUint("VERIFICATION_FEE") returns (uint256 fee) {
            verificationFee = fee;
        } catch {
            console.log("Using default verification fee:", verificationFee);
        }
        
        // Try to load aggregator from environment variable
        try vm.envAddress("AGGREGATOR_ADDRESS") returns (address addr) {
            aggregator = addr;
        } catch {
            // If aggregator isn't specified, use the deployer address
            aggregator = vm.addr(deployerPrivateKey);
            console.log("No aggregator specified, using deployer address:", aggregator);
        }
        
        // Log deployment parameters
        console.log("Deploying FlareFactChecker with:");
        console.log("- Verification Fee:", verificationFee);
        console.log("- Aggregator Address:", aggregator);
        
        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy the contract
        FlareFactChecker factChecker = new FlareFactChecker(verificationFee, aggregator);
        
        // Log deployment address
        console.log("FlareFactChecker deployed at:", address(factChecker));
        
        // Initial setup (optional)
        // Add deployer as a verifier
        factChecker.addVerifier(vm.addr(deployerPrivateKey));
        console.log("Added deployer as initial verifier");
        
        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}