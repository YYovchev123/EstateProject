// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {SharesToken} from "./SharesToken.sol";
import {Ownable} from "./lib/Ownable.sol";
import {Errors} from "./lib/Errors.sol";

/// @title EstateProject
/// @author YovchevYoan
/// @notice This is a contract resposible for raising funds for a real estate project.
/// @dev Through this contract users can buy apartments if the target funds have been raised
contract EstateProject is SharesToken, Ownable {
    /// @dev If the apartment has not been bought the owner is address(0)
    /// @param owner The owner of the apartment
    /// @param price The price of the apartment in WEI
    /// @param isBought Wether the apartment has been bought or not
    struct Apartment {
        address owner;
        uint256 price;
        bool isBought;
    }

    /// @notice Constant representing one hundred
    /// @dev To avoid magic numbers
    uint256 private constant ONE_HUNDRED = 100;

    /// @notice The location of the real estate property
    string private s_location;

    /// @notice The apartments available in the real estate property
    uint256 private s_apartmentsAvailable;

    /// @notice The target amount of funds to be fund raised
    uint256 private s_targetFundrasingAmount;

    /// @notice The deadline at which the fundrasing stops
    uint256 private s_deadline;

    /// @notice Whether the funds have been withdrawn or not
    bool private _isWithdrawn;

    /// @notice The total amount of funds collected by selling the apartments
    uint256 private _amountCollectedFromApartments;

    /// @notice Apartment ID => Apartment struct
    mapping(uint256 id => Apartment apartment) public s_apartments;

    /// @notice Investor => Amount invested
    mapping(address investor => uint256 amount) public s_inverstorToAmount;

    /// @notice Emmited when an investors invest into the real estate property
    /// @param investor The address of the investor
    /// @param amount The amount invested
    event Invest(address indexed investor, uint256 amount);

    /// @notice Emmited when an investors invest into the real estate property
    /// @param buyer THe address of the buyer of the apartment
    /// @param apartmentId The ID of the apartment bought
    event ApartmentBought(address indexed buyer, uint256 apartmentId);

    /// @notice Emmited when the owner withdraws the raised amount of funds
    /// @param to The address to which the funds are withdrawn
    /// @param amount The amount withdrawn
    event WithdrawFunds(address to, uint256 amount);

    /// @notice Emmited when an investor claims his award
    /// @param investor The address of the investor
    /// @param rewardAmount The amount of reward the investor receives
    event AwardDistributed(address indexed investor, uint256 rewardAmount);

    /// @notice Emmited when an investor withdraws investment after an unsuccessful project
    /// @param investor The address wanting to withdraw invested amount
    /// @param amount The invested amount being withdrawn
    event InvestmentRetreived(address indexed investor, uint256 amount);

    /// @dev The apartmentsAvailable should be alligned with the apartmentPrices array
    /// @param name  The name of the ShareToken
    /// @param symbol  The symbol of the ShareToken
    /// @param location  The location of the property
    /// @param deadline  The deadline until the funds should be raised
    /// @param apartmentsAvailable  The available apartments in the property
    /// @param targetFundrasingAmount  The target amount of funds that the property owner wants to raise
    /// @param apartmentsPrices  An array of the prices of each apartment correspoding to each apartment
    constructor(
        string memory name,
        string memory symbol,
        string memory location,
        uint256 deadline,
        uint256 apartmentsAvailable,
        uint256 targetFundrasingAmount,
        uint256[] memory apartmentsPrices
    ) SharesToken(name, symbol) Ownable(msg.sender) {
        if (apartmentsAvailable == 0) revert Errors.NotEnoughApartments();
        if (targetFundrasingAmount == 0) revert Errors.TargetAmountZero();
        if (apartmentsAvailable != apartmentsPrices.length)
            revert Errors.ApartmentsAvaibleDoesNotMatchPriceArray();
        if (deadline < block.timestamp) revert Errors.DeadlineAlreadyPassed();

        s_location = location;
        s_deadline = deadline;
        s_apartmentsAvailable = apartmentsAvailable;
        s_targetFundrasingAmount = targetFundrasingAmount;
        _isWithdrawn = false;

        //  Check if this will work properly
        for (uint256 i = 0; i < apartmentsPrices.length; i++) {
            s_apartments[i] = Apartment({
                owner: address(0),
                price: apartmentsPrices[i],
                isBought: false
            });
        }
    }

    /// @notice Called by investors to invest in the real estate project
    /// @dev Checks if the deadline has passed
    /// @dev Check if the target amount of founds has been collected, if yes it reverts
    /// @dev Mints SharesToken to the investor
    /// @dev Emits an event
    function invest() external payable {
        if (block.timestamp >= s_deadline)
            revert Errors.DeadlineAlreadyPassed();
        if (getTotalAmountInvested() > s_targetFundrasingAmount)
            revert Errors
                .FundrasingTargetAmountAlreadyCollectedOrIsBeingExceeded();

        uint256 amount = msg.value;
        s_inverstorToAmount[msg.sender] += amount;
        _mint(msg.sender, amount);

        emit Invest(msg.sender, amount);
    }

    /// @notice Called when a project has not collected the target fundrasing amount and the investor
    /// wants to withdraw his funds
    /// @dev The investor needs to provide his ShareTokens in order to receive his invested amount
    /// @dev Reverts if the deadline has not passed yet
    /// @dev Reverts if there is not invested amount
    /// @dev Reverts if the amount wanted is bigger than the amount invested
    /// @dev Reverts if the amount is collected before the deadline
    /// @dev Burns the ShareTokens of the investor
    /// @dev After all the checks have been completed the function transfers the `amount` to the investor
    function retreiveInvestment(uint256 amount) public {
        uint256 investedAmount = s_inverstorToAmount[msg.sender];
        if (block.timestamp < s_deadline)
            revert Errors.DeadlineHasNotPassedYet();
        if (investedAmount == 0) revert Errors.NoInvestmentMade();
        if (amount > investedAmount) revert Errors.AmountExceeds();
        if (isCollected())
            revert Errors
                .FundrasingTargetAmountAlreadyCollectedOrIsBeingExceeded();

        s_inverstorToAmount[msg.sender] -= amount;
        _burn(msg.sender, amount);

        emit InvestmentRetreived(msg.sender, amount);

        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) revert Errors.CallNotSuccessful();
    }

    /// @notice Called by the owner to withdraw the target funds if they have been collected
    /// @dev Reverts if the deadline has not passed
    /// @dev Reverts if the funds have already been withdrawn
    /// @dev Reverts if the target amount of funds has not been collected
    /// @dev Reverts if the provided address `to` is address(0)
    /// @dev Emits an event
    /// @dev Transfers the funds to the provided `to` address
    function withdrawFunds(address to) public onlyOwner {
        if (block.timestamp < s_deadline)
            revert Errors.DeadlineHasNotPassedYet();
        if (_isWithdrawn) revert Errors.FundsAlreadyWithdrawn();
        if (!isCollected()) revert Errors.TargetFundrasingAmountNotCollected();
        if (to == address(0)) revert Errors.AddressZero();

        _isWithdrawn = true;
        uint256 amount = getTotalAmountInvested();

        emit WithdrawFunds(to, amount);

        (bool success, ) = to.call{value: amount}("");
        if (!success) revert Errors.CallNotSuccessful();
    }

    /// @notice Called by a buyer who wants to buy an apartment by providing the required amount
    /// and the apartment ID
    /// @dev Can only be called only after the owner withdraws the target funds
    /// @dev Checks to see if apartments are available to be bought aka. if the funds have been withdrawn
    /// @dev Reverts if the apartment has already been bought
    /// @dev Reverts if the provided amount aka `msg.value` is lower than the expected price
    /// @return apartment Returns informantion about the apartment
    function buyApartment(
        uint256 apartmentId
    ) public payable returns (Apartment memory) {
        Apartment storage apartment = s_apartments[apartmentId];
        if (!_isWithdrawn) revert Errors.FundsNotWithdrawn();
        if (apartment.isBought) revert Errors.ApartmentAlreadyBought();
        if (apartment.price != msg.value)
            revert Errors.InsufficientPaymentAmount();

        apartment.isBought = true;
        apartment.owner = msg.sender;

        _amountCollectedFromApartments += msg.value;
        s_apartmentsAvailable--;

        emit ApartmentBought(msg.sender, apartmentId);

        return apartment;
    }

    /// @notice Called by investor when all the apartments have been bought to claim their reward
    /// @dev Reverts if all the apartments are not sold
    /// @dev Reverts if the user has nothing to claim
    /// @dev Reverts if the funds have not been withdrawn (just for safety)
    /// @dev Calculates the reward and transfers it to the investor
    /// @return reward Returns the reward amount
    function distributeRewards() public returns (uint256 reward) {
        uint256 investedAmount = s_inverstorToAmount[msg.sender];
        if (s_apartmentsAvailable != 0) revert Errors.NotAllApartmentsAreSold();
        if (investedAmount == 0) revert Errors.NoRewardsToClaim();
        if (!_isWithdrawn) revert Errors.FundsNotWithdrawn(); // check just for safety

        uint256 targetFundrasingAmount = s_targetFundrasingAmount;
        uint256 apartmentAmountCollected = _amountCollectedFromApartments;

        // TODO Check this calculation very carefully
        /// @dev This implementation of rewards distributes all the funds collected from the apartments
        /// @dev Might need to change later
        uint256 percentage = (investedAmount / targetFundrasingAmount) *
            ONE_HUNDRED;
        reward = (percentage / ONE_HUNDRED) * apartmentAmountCollected;

        s_inverstorToAmount[msg.sender] = 0;

        emit AwardDistributed(msg.sender, reward);

        (bool success, ) = msg.sender.call{value: reward}("");
        if (!success) revert Errors.CallNotSuccessful();
    }

    /// @notice Gets the totalAmountInvested in the contract while fundrasing
    /// @notice When the funds have been withdrawn, it gives us the funds collected for the apartments
    function getTotalAmountInvested() public view returns (uint256) {
        return address(this).balance;
    }

    /// @notice If the funds have been collected the function returns `true`, else `false`
    function isCollected() public view returns (bool) {
        return getTotalAmountInvested() >= s_targetFundrasingAmount;
    }

    /// @notice Returns the location
    function getLocation() external view returns (string memory) {
        return s_location;
    }

    /// @notice Returns the apartments available
    function getApartmentsAvailable() external view returns (uint256) {
        return s_apartmentsAvailable;
    }

    /// @notice Returns the target fundrasing amount
    function getTargetFundrasingAmount() external view returns (uint256) {
        return s_targetFundrasingAmount;
    }

    /// @notice Returns the deadline
    function getDeadline() external view returns (uint256) {
        return s_deadline;
    }

    /// @notice Returns the apartment for the specified apartmentId
    function getApartment(
        uint256 apartmentId
    ) public view returns (Apartment memory) {
        return s_apartments[apartmentId];
    }

    /// @notice Returns the amount collected from selling apartments
    function getAmountCollectedFromAppartments() public view returns (uint256) {
        return _amountCollectedFromApartments;
    }

    /// @notice Receive function, which for now just reverts, so it does not disturb the rewards distribution
    receive() external payable {
        revert();
    }
}
