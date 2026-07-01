// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../src/BikkoOracle.sol";
import "../src/HarvestToken.sol";
import "../src/BikkoLendingVault.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address adminSafe = vm.envAddress("ADMIN_SAFE");
        address timelock = vm.envAddress("TIMELOCK");
        address guardian = vm.envAddress("GUARDIAN");
        address usdc = vm.envAddress("USDC_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy Oracle
        BikkoOracle oracle = new BikkoOracle(adminSafe);

        // 2. Deploy HarvestToken
        HarvestToken harvestToken = new HarvestToken(adminSafe);

        // 3. Deploy BikkoLendingVault implementation
        BikkoLendingVault implementation = new BikkoLendingVault();

        // 4. Deploy ERC1967Proxy wrapping the implementation
        bytes memory initData = abi.encodeWithSelector(
            BikkoLendingVault.initialize.selector,
            adminSafe,
            timelock,
            guardian,
            address(harvestToken),
            address(oracle),
            usdc,
            7000,          // LTV 70%
            20000,         // Max single loan ($200 USDC cents)
            90 days        // Default duration
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);

        vm.stopBroadcast();

        console.log("Deployed Oracle:", address(oracle));
        console.log("Deployed HarvestToken:", address(harvestToken));
        console.log("Deployed LendingVault Implementation:", address(implementation));
        console.log("Deployed LendingVault Proxy:", address(proxy));
    }
}
