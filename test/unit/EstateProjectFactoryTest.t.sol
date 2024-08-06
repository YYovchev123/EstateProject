// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {console, Test} from "forge-std/Test.sol";
import {Errors} from "../../src/lib/Errors.sol";
import {EstateProjectFactory} from "../../src/EstateProjectFactory.sol";
import {EstateProject} from "../../src/EstateProject.sol";

contract EstateProjectFactoryTest is Test {
    // Events
    event EstateProjectCreated(
        address indexed initialOwner,
        EstateProject indexed estateProject
    );

    EstateProjectFactory estateProjectFactory;

    address deployer = makeAddr("deployer");
    address owner = makeAddr("owner");

    string name = "Estate Token";
    string symbol = "EST";
    string location = "Varna, Bulgaria";
    uint256 deadline = block.timestamp + 5 days;
    uint256 apartmentsAvailable = 3;
    uint256 targetFundrasingAmount = 20 ether;
    uint256[] apartmentPrices;

    function setUp() public {
        vm.prank(deployer);
        estateProjectFactory = new EstateProjectFactory();
    }

    modifier pushApartmentsToArray() {
        apartmentPrices.push(8 ether);
        apartmentPrices.push(15 ether);
        apartmentPrices.push(18 ether);
        _;
    }

    /*///////////////////////////////////////////////
            CREATE_ESTATE_PROJECT FUNCTION
    ///////////////////////////////////////////////*/
    function testCreateEstateProjectRevertsIfApartmentsAvailableIsZero()
        public
        pushApartmentsToArray
    {
        vm.prank(owner);
        vm.expectRevert(Errors.NotEnoughApartments.selector);
        estateProjectFactory.createEstateProject(
            name,
            symbol,
            location,
            deadline,
            0,
            targetFundrasingAmount,
            apartmentPrices
        );
    }

    function testCreateEstateProjectRevertsIfTargetFundrasingAmountIsZero()
        public
        pushApartmentsToArray
    {
        vm.prank(owner);
        vm.expectRevert(Errors.TargetAmountZero.selector);
        estateProjectFactory.createEstateProject(
            name,
            symbol,
            location,
            deadline,
            apartmentsAvailable,
            0,
            apartmentPrices
        );
    }

    function testCreateEstateProjectRevertsIfApartmentsAvailableDoesNotMatchApartmentPricesArrayLength()
        public
    {
        apartmentPrices.push(8 ether);
        apartmentPrices.push(15 ether);
        vm.prank(owner);
        vm.expectRevert(
            Errors.ApartmentsAvaibleDoesNotMatchPriceArray.selector
        );
        estateProjectFactory.createEstateProject(
            name,
            symbol,
            location,
            deadline,
            apartmentsAvailable,
            targetFundrasingAmount,
            apartmentPrices
        );
    }

    function testCreateEstateProjectIfDeadlineIsInThePast()
        public
        pushApartmentsToArray
    {
        uint256 timestamp = block.timestamp;
        vm.roll(10);
        vm.warp(1 days);

        vm.prank(owner);
        vm.expectRevert(Errors.DeadlineAlreadyPassed.selector);
        estateProjectFactory.createEstateProject(
            name,
            symbol,
            location,
            timestamp,
            apartmentsAvailable,
            targetFundrasingAmount,
            apartmentPrices
        );
    }

    function testCreateEstateProjectCreatesProjectAddsItToArray()
        public
        pushApartmentsToArray
    {
        vm.prank(owner);
        estateProjectFactory.createEstateProject(
            name,
            symbol,
            location,
            deadline,
            apartmentsAvailable,
            targetFundrasingAmount,
            apartmentPrices
        );
        assert(estateProjectFactory.getEstateProjectArrayLength() == 1);
    }
}
