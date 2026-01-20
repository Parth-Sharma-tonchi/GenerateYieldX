// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/Adapters/AaveAdaptar.sol";

contract DeployAaveAdapter is Script {
    function run() external returns (address) {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);
        console.log("Deployer:", deployer);

        // Required env vars: STAKED_ADDRESS (vault), AAVE_POOL, ATOKEN, ASSET
        address vault = vm.envAddress("STAKED_ADDRESS");
        address pool = vm.envAddress("AAVE_POOL");
        address aToken = vm.envAddress("ATOKEN");
        address asset = vm.envAddress("ASSET");

        if (vault == address(0)) revert("Please set STAKED_ADDRESS env var to the vault/staked contract address");
        if (pool == address(0)) revert("Please set AAVE_POOL env var to the Aave pool address");
        if (aToken == address(0)) revert("Please set ATOKEN env var to the aToken address");
        if (asset == address(0)) revert("Please set ASSET env var to the underlying asset address (USDC)");

        vm.startBroadcast(deployerKey);
        AaveV3Adapter adapter = new AaveV3Adapter(vault, pool, asset, aToken);
        vm.stopBroadcast();

        console.log("AaveV3Adapter deployed to:", address(adapter));
        return address(adapter);
    }
}
