// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {EstateProject} from "../../src/EstateProject.sol";

// THE TESTS CURRENTLY FAIL!!!
contract Handler is Test {
    EstateProject estateProject;
    address[] public investors;
    mapping(address investor => uint256 amount) public investorToAmount;
    uint256 public constant NUM_INVESTORS = 5;

    constructor(EstateProject _estateProject) {
        estateProject = _estateProject;
        for (uint256 i = 0; i < NUM_INVESTORS; i++) {
            investors.push(makeAddr(string(abi.encodePacked("Investor", i))));
        }
    }

    function invest(uint256 amount, uint256 investorIndex) public {
        investorIndex = bound(investorIndex, 0, NUM_INVESTORS - 1);
        amount = bound(amount, 1, 20 ether);
        address investorAddress = investors[investorIndex];

        uint256 currentTotal = estateProject.getTotalAmountInvested();
        uint256 targetAmount = estateProject.getTargetFundrasingAmount();
        if (currentTotal + amount > targetAmount) {
            amount = targetAmount - currentTotal;
        }

        if (amount == 0) return;

        vm.deal(investorAddress, amount);
        investorToAmount[investorAddress] += amount;

        vm.prank(investorAddress);
        estateProject.invest{value: amount}();
    }

    function retreiveInvestment(uint256 investorIndex, uint256 amount) public {
        investorIndex = bound(investorIndex, 0, NUM_INVESTORS - 1);
        address investorAddress = investors[investorIndex];
        amount = bound(amount, 0, investorToAmount[investorAddress]);

        if (amount == 0) return;

        vm.warp(estateProject.getDeadline() + 1);

        if (estateProject.isCollected()) return;

        vm.prank(investorAddress);
        estateProject.retreiveInvestment(amount);

        investorToAmount[investorAddress] -= amount;
    }

    function withdrawFunds() public {
        if (!estateProject.isCollected()) return;

        vm.warp(estateProject.getDeadline() + 1);

        vm.prank(estateProject.owner());
        estateProject.withdrawFunds(estateProject.owner());
    }

    function buyApartment(uint256 apartmentId, uint256 investorIndex) public {
        investorIndex = bound(investorIndex, 0, NUM_INVESTORS - 1);
        apartmentId = bound(apartmentId, 0, 2);
        address investorAddress = investors[investorIndex];

        if (!estateProject.isCollected()) return;

        EstateProject.Apartment memory apartment = estateProject.getApartment(apartmentId);
        if (apartment.isBought) return;

        vm.deal(investorAddress, apartment.price);
        vm.prank(investorAddress);
        estateProject.buyApartment{value: apartment.price}(apartmentId);
    }

    function distributeRewards(uint256 investorIndex) public {
        investorIndex = bound(investorIndex, 0, NUM_INVESTORS - 1);
        address investorAddress = investors[investorIndex];

        if (estateProject.getApartmentsAvailable() != 0) return;

        vm.prank(investorAddress);
        estateProject.distributeRewards();
    }
}
