// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/MockUSDC.sol";
import "../src/StakedUSDC.sol";

contract DeployStakedUSDC is Script {
    function run() external returns (address) {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);
        console.log("Deployer:", deployer);

        address usdcAddr = vm.envAddress("USDC_ADDRESS");

        vm.startBroadcast(deployerKey);

        MockUSDC usdc;
        if (usdcAddr == address(0)) {
            // deploy a local mock USDC if none provided
            usdc = new MockUSDC();
            usdcAddr = address(usdc);
            console.log("Deployed MockUSDC at:", usdcAddr);
        } else {
            usdc = MockUSDC(usdcAddr);
            console.log("Using existing USDC at:", usdcAddr);
        }

        address admin = vm.envAddress("ADMIN");
        if (admin == address(0)) admin = deployer;
        address manager = vm.envAddress("MANAGER");
        if (manager == address(0)) manager = deployer;

        StakedUSDC staked = new StakedUSDC(IERC20(usdcAddr), admin, manager);

        vm.stopBroadcast();

        console.log("StakedUSDC deployed to:", address(staked));
        return address(staked);
    }
}
