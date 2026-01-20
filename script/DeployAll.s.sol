// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/MockUSDC.sol";
import "../src/StakedUSDC.sol";
import "../src/Adapters/AaveAdaptar.sol";
import "../src/Adapters/CompoundAdaptar.sol";

contract DeployAll is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);
        console.log("Deployer:", deployer);

        // Optional env overrides
        address existingUsdc = vm.envAddress("USDC_ADDRESS");
        address aavePool = vm.envAddress("AAVE_POOL");
        address aToken = vm.envAddress("ATOKEN");
        address comet = vm.envAddress("COMET");

        vm.startBroadcast(deployerKey);

        // 1) USDC
        MockUSDC usdc;
        if (existingUsdc == address(0)) {
            usdc = new MockUSDC();
            console.log("Deployed MockUSDC at:", address(usdc));
        } else {
            usdc = MockUSDC(existingUsdc);
            console.log("Using existing USDC at:", existingUsdc);
        }

        // 2) StakedUSDC
        address admin = vm.envAddress("ADMIN");
        if (admin == address(0)) admin = deployer;
        address manager = vm.envAddress("MANAGER");
        if (manager == address(0)) manager = deployer;

        StakedUSDC staked = new StakedUSDC(IERC20(address(usdc)), admin, manager);
        console.log("StakedUSDC deployed at:", address(staked));

        // 3) Aave Adapter (optional, requires env vars)
        if (aavePool != address(0) && aToken != address(0)) {
            AaveV3Adapter aave = new AaveV3Adapter(address(staked), aavePool, address(usdc), aToken);
            console.log("AaveV3Adapter deployed at:", address(aave));
            // Note: the vault (staked) will need to call addAdapter(address(aave)) after deployment
        } else {
            console.log("Skipping Aave adapter deployment: set AAVE_POOL and ATOKEN env vars to enable");
        }

        // 4) Compound Adapter (optional)
        if (comet != address(0)) {
            CompoundV3Adapter c = new CompoundV3Adapter(address(staked), comet, address(usdc));
            console.log("CompoundV3Adapter deployed at:", address(c));
        } else {
            console.log("Skipping Compound adapter deployment: set COMET env var to enable");
        }

        vm.stopBroadcast();

        console.log("Deployment script finished.");
        console.log("TIP: If adapters were deployed, call staked.addAdapter(adapterAddress) from the admin to register them.");
    }
}
