// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {EstateProject} from "../../src/EstateProject.sol";
import {Handler} from "./Handler.t.sol";

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
    }

    // This should only hold when the deadline has not passed
    function invariant_totalAmountInvestedShouldNotBeMoreThanTargetFundrasingAmount() public view {
        uint256 _targetFundrasingAmount = estateProject.getTargetFundrasingAmount();
        uint256 _totalAmountInvested = estateProject.getTotalAmountInvested();

        assert(_totalAmountInvested <= _targetFundrasingAmount);
    }

    function invariant_retreiveInvestmentShouldOnlyBeCalledWhenDeadlineHasPassedAndTargetNotReached() public {}
}
