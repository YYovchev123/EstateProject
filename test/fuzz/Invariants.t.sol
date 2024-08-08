// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {EstateProject} from "../../src/EstateProject.sol";
import {Handler} from "./Handler.t.sol";

// THE TESTS CURRENTLY FAIL!!!
contract Invariants is StdInvariant, Test {
    EstateProject estateProject;
    Handler handler;

    string name = "Estate Token";
    string symbol = "EST";
    string location = "Varna, Bulgaria";
    uint256 deadline = block.timestamp + 5 days;
    uint256 apartmentsAvailable = 3;
    uint256 targetFundrasingAmount = 20 ether;
    uint256[] apartmentPrices;

    function setUp() external {
        apartmentPrices.push(8 ether);
        apartmentPrices.push(15 ether);
        apartmentPrices.push(18 ether);

        estateProject = new EstateProject(
            name, symbol, location, deadline, apartmentsAvailable, targetFundrasingAmount, apartmentPrices
        );
        handler = new Handler(estateProject);

        targetContract(address(handler));

        bytes4[] memory selectors = new bytes4[](5);
        selectors[0] = Handler.invest.selector;
        selectors[1] = Handler.retreiveInvestment.selector;
        selectors[2] = Handler.withdrawFunds.selector;
        selectors[3] = Handler.buyApartment.selector;
        selectors[4] = Handler.distributeRewards.selector;

        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));

        excludeContract(address(estateProject));
    }

    function invariant_totalAmountInvestedShouldNotBeMoreThanTargetFundrasingAmount() public view {
        uint256 _targetFundrasingAmount = estateProject.getTargetFundrasingAmount();
        uint256 _totalAmountInvested = estateProject.getTotalAmountInvested();

        assert(_totalAmountInvested <= _targetFundrasingAmount);
    }

    function invariant_totalSupplyShouldEqualTotalAmountInvested() public view {
        uint256 _totalSupply = estateProject.totalSupply();
        uint256 _totalAmountInvested = estateProject.getTotalAmountInvested();

        assert(_totalSupply == _totalAmountInvested);
    }

    // function invariant_apartmentsAvailableShouldDecrease() public view {
    //     uint256 _initialApartments = apartmentsAvailable;
    //     uint256 _currentApartments = estateProject.getApartmentsAvailable();

    //     assert(_currentApartments <= _initialApartments);
    // }

    function invariant_collectedAmountShouldNotExceedTotalApartmentPrices() public view {
        uint256 _amountCollected = estateProject.getAmountCollectedFromAppartments();
        uint256 _totalApartmentPrices = 0;
        for (uint256 i = 0; i < apartmentPrices.length; i++) {
            _totalApartmentPrices += apartmentPrices[i];
        }

        assert(_amountCollected <= _totalApartmentPrices);
    }

    // function invariant_contractBalanceShouldBeConsistent() public view {
    //     uint256 _contractBalance = address(estateProject).balance;
    //     uint256 _totalAmountInvested = estateProject.getTotalAmountInvested();
    //     uint256 _amountCollectedFromApartments = estateProject.getAmountCollectedFromAppartments();

    //     assert(_contractBalance == _totalAmountInvested + _amountCollectedFromApartments);
    // }
}
