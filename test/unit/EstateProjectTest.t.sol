// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console, Test} from "forge-std/Test.sol";
import {EstateProject} from "../../src/EstateProject.sol";
import {Errors} from "../../src/lib/Errors.sol";

contract EstateProjectTest is Test {
    // Events
    event Invest(address indexed investor, uint256 amount);

    uint256[] appartmentPrices;

    EstateProject estateProject;

    address owner = makeAddr("owner");
    address userOne = makeAddr("userOne");
    address userTwo = makeAddr("userTwo");
    address userThree = makeAddr("userThree");

    function setUp() public {
        string memory name = "Estate Token";
        string memory symbol = "EST";
        string memory location = "Varna, Bulgaria";
        uint256 deadline = block.timestamp + 5 days;
        uint256 appartmentsAvailable = 3;
        uint256 targetFundrasingAmount = 20 ether;

        appartmentPrices.push(1000);
        appartmentPrices.push(1270);
        appartmentPrices.push(1310);

        vm.prank(owner);
        estateProject = new EstateProject(
            name,
            symbol,
            location,
            deadline,
            appartmentsAvailable,
            targetFundrasingAmount,
            appartmentPrices
        );

        vm.deal(userOne, 10 ether);
        vm.deal(userTwo, 5 ether);
        vm.deal(userThree, 15 ether);
    }

    /*///////////////////////////////////////////////
                    INVEST FUNCTION
    ///////////////////////////////////////////////*/
    function testInvestMintsShareTokensAndEmitsEvent() public {
        uint256 amount = 1 ether;

        vm.prank(userOne);
        vm.expectEmit(address(estateProject));
        emit Invest(userOne, amount);
        estateProject.invest{value: amount}();

        uint256 userOneExpectedSharesBalance = amount;
        uint256 userOneActualSharesBalance = estateProject.balanceOf(userOne);

        assert(userOneActualSharesBalance == userOneExpectedSharesBalance);
    }

    function testInvestRevertsIfDeadlineHasPassed() public {
        vm.roll(100);
        vm.warp(6 days);

        vm.prank(userOne);
        vm.expectRevert(Errors.DeadlineAlreadyPassed.selector);
        estateProject.invest{value: 1 ether}();
    }

    function testInvestRevertsIfTheFundrasingTargetAmontHasBeenCollected()
        public
    {
        uint256 amountOne = 8 ether;
        uint256 amountTwo = 1 ether;
        uint256 amountThree = 12 ether;
        vm.prank(userOne);
        estateProject.invest{value: amountOne}();

        vm.prank(userThree);
        estateProject.invest{value: amountThree}();

        vm.prank(userThree);
        vm.expectRevert(
            Errors
                .FundrasingTargetAmountAlreadyCollectedOrIsBeingExceeded
                .selector
        );
        estateProject.invest{value: amountTwo}();
    }

    /*///////////////////////////////////////////////
                RETREIVE_INVESTMENT FUNCTION
    ///////////////////////////////////////////////*/
    function testRetreiveInvestmentRevertsIfTheDeadlineHasNotPassed() public {}

    function testRetreiveInvestmentRevertsIfInvestedUserAmountIsZero() public {}

    function testRetreiveInvestmentRevertsIfAmountIsBiggerThanInvestment()
        public
    {}

    function testRetreiveInvestmentEmitsEventBurnSharesAndTransfersEthBack()
        public
    {}
}
