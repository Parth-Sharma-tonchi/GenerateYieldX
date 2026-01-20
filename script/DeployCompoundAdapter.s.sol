// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/Adapters/CompoundAdaptar.sol";

contract DeployCompoundAdapter is Script {
    function run() external returns (address) {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);
        console.log("Deployer:", deployer);

        // Required env vars: STAKED_ADDRESS (vault), COMET, ASSET
        address vault = vm.envAddress("STAKED_ADDRESS");
        address comet = vm.envAddress("COMET");
        address asset = vm.envAddress("ASSET");

        if (vault == address(0)) revert("Please set STAKED_ADDRESS env var to the vault/staked contract address");
        if (comet == address(0)) revert("Please set COMET env var to the Compound Comet address");
        if (asset == address(0)) revert("Please set ASSET env var to the underlying asset address (USDC)");

        vm.startBroadcast(deployerKey);
        CompoundV3Adapter adapter = new CompoundV3Adapter(vault, comet, asset);
        vm.stopBroadcast();

        console.log("CompoundV3Adapter deployed to:", address(adapter));
        return address(adapter);
    }
}
