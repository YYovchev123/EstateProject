// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {EstateProject} from "../../src/EstateProject.sol";

contract Handler is Test {
    EstateProject estateProject;
    address[] investors;
    mapping(uint256 invetor => uint256 amount) investorToAmount;
    address investorOne = makeAddr("InvestorOne");
    address investorTwo = makeAddr("investorTwo");
    address investorThree = makeAddr("investorThree");
    address investorFour = makeAddr("investorFour");
    address investorFive = makeAddr("investorFive");

    constructor(EstateProject _estateProject) {
        investors.push(investorOne);
        investors.push(investorTwo);
        investors.push(investorThree);
        investors.push(investorFour);
        investors.push(investorFive);
        estateProject = _estateProject;
    }

    function invest(uint256 amount, uint256 investor) public {
        // if (amount + estateProject.getTotalAmountInvested() > estateProject.getTargetFundrasingAmount()) {
        //     return;
        // }
        bound(investor, 0, 4);
        bound(amount, 1, 20 ether);
        address investorAddress = investors[investor];
        vm.deal(investorAddress, amount);

        investorToAmount[investor] += amount;

        vm.prank(investorAddress);
        estateProject.invest{value: amount}();
    }

    // function retreiveInvestment(uint256 investor, uint256 amount) public {
    //     // if()
    //     // vm.roll(100);
    //     // vm.warp(10 days);
    //     bound(investor, 0, 4);
    //     bound(amount, 1, investorToAmount[investor]);

    //     address investorAddress = investors[investor];
    //     investorToAmount[investor] -= amount;

    //     vm.prank(investorAddress);
    //     estateProject.invest{value: amount}();
    // }
}
