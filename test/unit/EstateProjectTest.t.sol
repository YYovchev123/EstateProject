// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console, Test} from "forge-std/Test.sol";
import {EstateProject} from "../../src/EstateProject.sol";
import {Errors} from "../../src/lib/Errors.sol";

contract EstateProjectTest is Test {
    // Events
    event Invest(address indexed investor, uint256 amount);
    event InvestmentRetreived(address indexed investor, uint256 amount);
    event WithdrawFunds(address to, uint256 amount);
    event ApartmentBought(address indexed buyer, uint256 apartmentId);
    event AwardDistributed(address indexed investor, uint256 rewardAmount);

    uint256[] apartmentPrices;

    EstateProject estateProject;

    address owner = makeAddr("owner");
    address userOne = makeAddr("userOne");
    address userTwo = makeAddr("userTwo");
    address userThree = makeAddr("userThree");
    address treasury = makeAddr("treasury");

    string name = "Estate Token";
    string symbol = "EST";
    string location = "Varna, Bulgaria";
    uint256 deadline = block.timestamp + 5 days;
    uint256 apartmentsAvailable = 3;
    uint256 targetFundrasingAmount = 20 ether;

    function setUp() public {
        apartmentPrices.push(8 ether);
        apartmentPrices.push(15 ether);
        apartmentPrices.push(18 ether);

        vm.prank(owner);
        estateProject = new EstateProject(
            name,
            symbol,
            location,
            deadline,
            apartmentsAvailable,
            targetFundrasingAmount,
            apartmentPrices
        );

        vm.deal(userOne, 100 ether);
        vm.deal(userTwo, 50 ether);
        vm.deal(userThree, 150 ether);
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
    modifier rollUpTime() {
        vm.roll(100);
        vm.warp(6 days);
        _;
    }

    modifier userOneInvest() {
        uint256 amount = 1 ether;
        vm.prank(userOne);
        estateProject.invest{value: amount}();
        _;
    }

    modifier collectTargetFunds() {
        uint256 amountOne = 8 ether;
        uint256 amountTwo = 12 ether;
        vm.prank(userOne);
        estateProject.invest{value: amountOne}();

        vm.prank(userThree);
        estateProject.invest{value: amountTwo}();
        _;
    }

    function testRetreiveInvestmentRevertsIfTheDeadlineHasNotPassed() public {
        vm.prank(userOne);
        vm.expectRevert(Errors.DeadlineHasNotPassedYet.selector);
        estateProject.retreiveInvestment(1);
    }

    function testRetreiveInvestmentRevertsIfInvestedUserAmountIsZero()
        public
        rollUpTime
    {
        vm.prank(userOne);
        vm.expectRevert(Errors.NoInvestmentMade.selector);
        estateProject.retreiveInvestment(1);
    }

    function testRetreiveInvestmentRevertsIfAmountIsBiggerThanInvestment()
        public
        userOneInvest
        rollUpTime
    {
        vm.prank(userOne);
        vm.expectRevert(Errors.AmountExceeds.selector);
        estateProject.retreiveInvestment(2 ether);
    }

    function testRetreiveInvestmentRevertsIfTheAmountHasAlreadyBeenCollected()
        public
        collectTargetFunds
        rollUpTime
    {
        vm.prank(userOne);
        vm.expectRevert(
            Errors
                .FundrasingTargetAmountAlreadyCollectedOrIsBeingExceeded
                .selector
        );
        estateProject.retreiveInvestment(8 ether);
    }

    function testRetreiveInvestmentEmitsEventBurnSharesAndTransfersEthBack()
        public
    {
        uint256 amountOne = 7 ether;
        uint256 amountTwo = 12 ether;
        vm.prank(userOne);
        estateProject.invest{value: amountOne}();

        uint256 userOneSharesBefore = estateProject.balanceOf(userOne);
        uint256 userOneETHBalanceBefore = address(userOne).balance;

        vm.prank(userThree);
        estateProject.invest{value: amountTwo}();

        vm.roll(100);
        vm.warp(6 days);

        vm.prank(userOne);
        vm.expectEmit(address(estateProject));
        emit InvestmentRetreived(userOne, amountOne);
        estateProject.retreiveInvestment(amountOne);

        uint256 actualUserOneSharesAfter = estateProject.balanceOf(userOne);
        uint256 expectedUserOneSharesAfter = userOneSharesBefore - amountOne;

        uint256 actualUserOneETHBalanceAfter = address(userOne).balance;
        uint256 expectedUserOneETHBalanceAfter = userOneETHBalanceBefore +
            amountOne;

        assert(actualUserOneSharesAfter == expectedUserOneSharesAfter);
        assert(actualUserOneETHBalanceAfter == expectedUserOneETHBalanceAfter);
    }

    /*///////////////////////////////////////////////
                WITHDRAW_FUNDS FUNCTION
    ///////////////////////////////////////////////*/
    function testWithdrawFundsRevertsIfDeadlineHasNotPassed()
        public
        userOneInvest
    {
        vm.prank(owner);
        vm.expectRevert(Errors.DeadlineHasNotPassedYet.selector);
        estateProject.withdrawFunds(treasury);
    }

    function testWithdrawFundsRevertsIfTheTargetFundrasingAmountIsNotCollected()
        public
        userOneInvest
        rollUpTime
    {
        vm.prank(owner);
        vm.expectRevert(Errors.TargetFundrasingAmountNotCollected.selector);
        estateProject.withdrawFunds(treasury);
    }

    function testWithdrawFundsRevertsIfToIsAddressZero()
        public
        collectTargetFunds
        rollUpTime
    {
        vm.prank(owner);
        vm.expectRevert(Errors.AddressZero.selector);
        estateProject.withdrawFunds(address(0));
    }

    function testWithdrawFundsRevertsIfTheFundsHaveAlreadyBeenWithdrawn()
        public
        collectTargetFunds
        rollUpTime
    {
        vm.prank(owner);
        estateProject.withdrawFunds(treasury);

        console.log("I donat asosieit wit nigurs");

        vm.prank(owner);
        vm.expectRevert(Errors.FundsAlreadyWithdrawn.selector);
        estateProject.withdrawFunds(treasury);
    }

    function testWithdrawFundsRevertsIfNotCalledByOwner()
        public
        collectTargetFunds
        rollUpTime
    {
        vm.prank(userOne);
        vm.expectRevert(Errors.NotOwner.selector);
        estateProject.withdrawFunds(treasury);
    }

    function testWithdrawFundsEmitsAnEventAndTransferesAllCollectedFundsToSpecifiedAddress()
        public
        collectTargetFunds
        rollUpTime
    {
        uint256 targetAmount = 20 ether;
        uint256 treasuryBalanceBefore = address(treasury).balance;

        vm.prank(owner);
        vm.expectEmit(address(estateProject));
        emit WithdrawFunds(treasury, targetAmount);
        estateProject.withdrawFunds(treasury);

        uint256 expectedTreasuryBalanceAfter = targetAmount +
            treasuryBalanceBefore;
        uint256 actualTrasuryBalanceAfter = address(treasury).balance;

        assert(expectedTreasuryBalanceAfter == actualTrasuryBalanceAfter);
    }

    /*///////////////////////////////////////////////
                WITHDRAW_FUNDS FUNCTION
    ///////////////////////////////////////////////*/
    modifier ownerWithdrawsFunds() {
        vm.prank(owner);
        estateProject.withdrawFunds(treasury);
        _;
    }

    function testBuyApartmentRevertsIfTheFundsHaveNotBeenWithdrawn()
        public
        collectTargetFunds
        rollUpTime
    {
        vm.prank(userOne);
        vm.expectRevert(Errors.FundsNotWithdrawn.selector);
        estateProject.buyApartment{value: 8 ether}(0);
    }

    function testBuyApartmentRevertsIfTheApartmentHasBeenBought()
        public
        collectTargetFunds
        rollUpTime
        ownerWithdrawsFunds
    {
        uint256 apartmentId = 0;

        vm.prank(userOne);
        estateProject.buyApartment{value: 8 ether}(apartmentId);

        console.log(
            "Apartment 0 isBought: ",
            estateProject.getApartment(apartmentId).isBought
        );
        console.log(
            "Apartment 0 owner: ",
            estateProject.getApartment(apartmentId).owner
        );

        vm.prank(userTwo);
        vm.expectRevert(Errors.ApartmentAlreadyBought.selector);
        estateProject.buyApartment{value: 8 ether}(apartmentId);
    }

    function testBuyApartmentRevertsIfProvidedPriceDoesNotMsgValue()
        public
        collectTargetFunds
        rollUpTime
        ownerWithdrawsFunds
    {
        vm.prank(userOne);
        vm.expectRevert(Errors.InsufficientPaymentAmount.selector);
        estateProject.buyApartment{value: 7 ether}(0);
    }

    function testBuyApartmentReceivesAmountAndEmitsEvent()
        public
        collectTargetFunds
        rollUpTime
        ownerWithdrawsFunds
    {
        uint256 apartmentId = 0;
        uint256 amount = 8 ether;
        uint256 estateProjectBalanceBefore = address(estateProject).balance;

        vm.prank(userOne);
        vm.expectEmit(address(estateProject));
        emit ApartmentBought(userOne, apartmentId);
        estateProject.buyApartment{value: amount}(apartmentId);

        uint256 actualEstateProjectBalanceAfter = address(estateProject)
            .balance;
        uint256 expectedEstateProjectBalanceAfter = estateProjectBalanceBefore +
            amount;

        assert(
            expectedEstateProjectBalanceAfter == actualEstateProjectBalanceAfter
        );
    }

    /*///////////////////////////////////////////////
                DISTRIBUTE_FUNDS FUNCTION
    ///////////////////////////////////////////////*/
    modifier buyAllApartments() {
        vm.prank(userOne);
        estateProject.buyApartment{value: 8 ether}(0);

        vm.prank(userTwo);
        estateProject.buyApartment{value: 15 ether}(1);

        vm.prank(userThree);
        estateProject.buyApartment{value: 18 ether}(2);
        _;
    }

    function testDistributeFundsRevertsIfNotAllApartmentsAreSold()
        public
        collectTargetFunds
        rollUpTime
        ownerWithdrawsFunds
    {
        vm.prank(userOne);
        vm.expectRevert(Errors.NotAllApartmentsAreSold.selector);
        estateProject.distributeRewards();
    }

    function testDistributeFundsRevetsIfInvestedAmountIsZero()
        public
        collectTargetFunds
        rollUpTime
        ownerWithdrawsFunds
        buyAllApartments
    {
        vm.prank(userTwo);
        vm.expectRevert(Errors.NoRewardsToClaim.selector);
        estateProject.distributeRewards();
    }

    function testDistributeFundsEmitAnEventAndDistributesTheProperRewardToInvestor()
        public
        collectTargetFunds
        rollUpTime
        ownerWithdrawsFunds
        buyAllApartments
    {
        assert(
            address(estateProject).balance ==
                estateProject.getAmountCollectedFromAppartments()
        );
        uint256 oneHundred = 100;
        uint256 percentage = (estateProject.s_inverstorToAmount(userOne) /
            targetFundrasingAmount) * oneHundred;
        uint256 expectedReward = (percentage / oneHundred) *
            estateProject.getAmountCollectedFromAppartments();

        vm.prank(userOne);
        vm.expectEmit(address(estateProject));
        emit AwardDistributed(userOne, expectedReward);
        uint256 actualReward = estateProject.distributeRewards();

        assert(expectedReward == actualReward);
    }
}
