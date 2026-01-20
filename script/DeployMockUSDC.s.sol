// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/MockUSDC.sol";

contract DeployMockUSDC is Script {
    function run() external returns (address) {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);

        console.log("Deployer:", deployer);

        vm.startBroadcast(deployerKey);
        MockUSDC token = new MockUSDC();
        vm.stopBroadcast();

        console.log("MockUSDC deployed to:", address(token));
        return address(token);
    }
}
