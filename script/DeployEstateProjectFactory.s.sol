// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {EstateProjectFactory} from "../src/EstateProjectFactory.sol";

contract DeployEstateProjectFactory is Script {
    function run() external returns (EstateProjectFactory) {
        vm.startBroadcast();
        EstateProjectFactory estateProjectFactory = new EstateProjectFactory();
        vm.stopBroadcast();
        return estateProjectFactory;
    }
}
