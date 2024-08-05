// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {SharesToken} from "./SharesToken.sol";
import {Ownable} from "./lib/Ownable.sol";
import {Errors} from "./lib/Errors.sol";

/// @title EstateProject
/// @author YovchevYoan
/// @notice This is a contract resposible for raising funds for a real estate project.
/// @dev Through this contract users can buy appartments if the target funds have been raised
contract EstateProject is SharesToken, Ownable {
    /// @dev If the appartment has not been bought the owner is address(0)
    /// @param owner The owner of the appartment
    /// @param price The price of the appartment in WEI
    /// @param isBought Wether the appartment has been bought or not
    struct Appartment {
        address owner;
        uint256 price;
        bool isBought;
    }

    /// @notice Constant representing one hundred
    /// @dev To avoid magic numbers
    uint256 private constant ONE_HUNDRED = 100;

    /// @notice The location of the real estate property
    string private s_location;

    /// @notice The appartments available in the real estate property
    uint256 private s_appartmentsAvailable;

    /// @notice The target amount of funds to be fund raised
    uint256 private s_targetFundrasingAmount;

    /// @notice The deadline at which the fundrasing stops
    uint256 private s_deadline;

    /// @notice Whether the funds have been withdrawn or not
    bool private _isWithdrawn;

    /// @notice The total amount of funds collected by selling the appartments
    uint256 private _amountCollectedFromAppartments;

    /// @notice Appartment ID => Appartment struct
    mapping(uint256 id => Appartment appartment) s_appartments;

    /// @notice Investor => Amount invested
    mapping(address investor => uint256 amount) s_inverstorToAmount;

    /// @notice Emmited when an investors invest into the real estate property
    /// @param investor The address of the investor
    /// @param amount The amount invested
    event Invest(address indexed investor, uint256 amount);

    /// @notice Emmited when an investors invest into the real estate property
    /// @param buyer THe address of the buyer of the appartment
    /// @param appartmentId The ID of the appartment bought
    event AppartmentBought(address indexed buyer, uint256 appartmentId);

    /// @notice Emmited when the owner withdraws the raised amount of funds
    /// @param to The address to which the funds are withdrawn
    /// @param amount The amount withdrawn
    event WithdrawFunds(address to, uint256 amount);

    /// @notice Emmited when an investor claims his award
    /// @param investor The address of the investor
    /// @param rewardAmount The amount of reward the investor receives
    event AwardDistributed(address investor, uint256 rewardAmount);

    /// @notice Emmited when an investor withdraws investment after an unsuccessful project
    /// @param investor The address wanting to withdraw invested amount
    /// @param amount The invested amount being withdrawn
    event InvestmentRetreived(address investor, uint256 amount);

    /// @dev The appartmentsAvailable should be alligned with the appartmentPrices array
    /// @param name  The name of the ShareToken
    /// @param symbol  The symbol of the ShareToken
    /// @param location  The location of the property
    /// @param deadline  The deadline until the funds should be raised
    /// @param appartmentsAvailable  The available appartments in the property
    /// @param targetFundrasingAmount  The target amount of funds that the property owner wants to raise
    /// @param appartmentsPrices  An array of the prices of each appartment correspoding to each appartment
    constructor(
        string memory name,
        string memory symbol,
        string memory location,
        uint256 deadline,
        uint256 appartmentsAvailable,
        uint256 targetFundrasingAmount,
        uint256[] memory appartmentsPrices
    ) SharesToken(name, symbol) Ownable(msg.sender) {
        if (appartmentsAvailable == 0) revert Errors.NotEnoughAppartments();
        if (targetFundrasingAmount == 0) revert Errors.TargetAmountZero();
        if (appartmentsAvailable != appartmentsPrices.length)
            revert Errors.AppartmentsAvaibleDoesNotMatchPriceArray();
        if (deadline < block.timestamp) revert Errors.DeadlineAlreadyPassed();

        s_location = location;
        s_deadline = deadline;
        s_appartmentsAvailable = appartmentsAvailable;
        s_targetFundrasingAmount = targetFundrasingAmount;
        _isWithdrawn = false;

        //  Check if this will work properly
        for (uint256 i = 0; i < appartmentsPrices.length; i++) {
            s_appartments[i] = Appartment({
                owner: address(0),
                price: appartmentsPrices[i],
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
    /// @dev Burns the ShareTokens of the investor
    /// @dev After all the checks have been completed the function transfers the `amount` to the investor
    function retreiveInvestment(uint256 amount) public {
        uint256 investedAmount = s_inverstorToAmount[msg.sender];
        if (block.timestamp < s_deadline)
            revert Errors.DeadlineHasNotPassedYet();
        if (investedAmount == 0) revert Errors.NoInvestmentMade();
        if (amount > investedAmount) revert Errors.AmountExceeds();

        s_inverstorToAmount[msg.sender] -= amount;
        _burn(msg.sender, amount);

        emit InvestmentRetreived(msg.sender, amount);

        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) revert Errors.CallNotSuccessful();
    }

    /// @notice Called by the owner to withdraw the target funds if they have been collected
    /// @dev Reverts if the deadline has not passed
    /// @dev Reverts if the target amount of funds has not been collected
    /// @dev Reverts if the provided address `to` is address(0)
    /// @dev Reverts if the funds have already been withdrawn
    /// @dev Emits an event
    /// @dev Transfers the funds to the provided `to` address
    function withdrawFunds(address to) public onlyOwner {
        if (block.timestamp < s_deadline)
            revert Errors.DeadlineHasNotPassedYet();
        if (!isCollected()) revert Errors.TargetFundrasingAmountNotCollected();
        if (to == address(0)) revert Errors.AddressZero();
        if (_isWithdrawn) revert Errors.FundsAlreadyWithdrawn();

        _isWithdrawn = true;
        uint256 amount = getTotalAmountInvested();

        emit WithdrawFunds(to, amount);

        (bool success, ) = to.call{value: amount}("");
        if (!success) revert Errors.CallNotSuccessful();
    }

    /// @notice Called by a buyer who wants to buy an appartment by providing the required amount
    /// and the appartment ID
    /// @dev Checks to see if appartments are available to be bought aka. if the funds have been withdrawn
    /// @dev Reverts if the appartment has already been bought
    /// @dev Reverts if the provided amount aka `msg.value` is lower than the expected price
    /// @return appartment Returns informantion about the appartment
    function buyAppartment(
        uint256 appartmentId
    ) public payable returns (Appartment memory appartment) {
        appartment = s_appartments[appartmentId];
        if (!_isWithdrawn) revert Errors.FundsNotWithdrawn();
        if (appartment.isBought) revert Errors.AppartmentAlreadyBought();
        if (appartment.price != msg.value)
            revert Errors.InsufficientPaymentAmount();

        appartment.isBought = true;
        appartment.owner = msg.sender;

        _amountCollectedFromAppartments += msg.value;
        s_appartmentsAvailable--;

        emit AppartmentBought(msg.sender, appartmentId);
    }

    /// @notice Called by investor when all the appartments have been bought to claim their reward
    /// @dev Reverts if all the apartments are not sold
    /// @dev Reverts if the user has nothing to claim
    /// @dev Reverts if the funds have not been withdrawn (just for safety)
    /// @dev Calculates the reward and transfers it to the investor
    /// @return reward Returns the reward amount
    function distributeRewards() public payable returns (uint256 reward) {
        uint256 investedAmount = s_inverstorToAmount[msg.sender];
        if (s_appartmentsAvailable != 0)
            revert Errors.NotAllApartmentsAreSold();
        if (investedAmount == 0) revert Errors.NoRewardsToClaim();
        if (!_isWithdrawn) revert Errors.FundsNotWithdrawn(); // check just for safety

        uint256 targetFundrasingAmount = s_targetFundrasingAmount;
        uint256 appartmentAmountCollected = _amountCollectedFromAppartments;

        // TODO Check this calculation very carefully
        /// @dev This implementation of rewards distributes all the funds collected from the appartments
        /// @dev Might need to change later
        uint256 percentage = (investedAmount / targetFundrasingAmount) *
            ONE_HUNDRED;
        reward = (percentage / ONE_HUNDRED) * appartmentAmountCollected;

        s_inverstorToAmount[msg.sender] = 0;

        emit AwardDistributed(msg.sender, reward);

        (bool success, ) = msg.sender.call{value: reward}("");
        if (!success) revert Errors.CallNotSuccessful();
    }

    /// @notice Gets the totalAmountInvested in the contract while fundrasing
    /// @notice When the funds have been withdrawn, it gives us the funds collected for the appartments
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

    /// @notice Returns the appartments available
    function getAppartmentsAvailable() external view returns (uint256) {
        return s_appartmentsAvailable;
    }

    /// @notice Returns the target fundrasing amount
    function getTargetFundrasingAmount() external view returns (uint256) {
        return s_targetFundrasingAmount;
    }

    /// @notice Returns the deadline
    function getDeadline() external view returns (uint256) {
        return s_deadline;
    }

    /// @notice Receive function, which for now just reverts, so it does not disturb the rewards distribution
    receive() external payable {
        revert();
    }
}
