// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {EstateProject} from "../src/EstateProject.sol";

contract DeployEstateProject is Script {
    function run(
        string memory name,
        string memory symbol,
        string memory location,
        uint256 deadline,
        uint256 apartmentsAvailable,
        uint256 targetFundrasingAmount,
        uint256[] memory apartmentPrices
    ) external returns (EstateProject) {
        vm.startBroadcast();
        EstateProject estateProject = new EstateProject({
            name: name,
            symbol: symbol,
            location: location,
            deadline: deadline,
            apartmentsAvailable: apartmentsAvailable,
            targetFundrasingAmount: targetFundrasingAmount,
            apartmentsPrices: apartmentPrices
        });
        vm.stopBroadcast();
        return estateProject;
    }
}
