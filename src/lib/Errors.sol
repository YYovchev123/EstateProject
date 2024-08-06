// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @title Errors
/// @author YovchevYoan
/// @notice Library containing the errors
library Errors {
    /// @notice When the amount has been exceeded
    error AmountExceeds();
    /// @notice When the apartments provided are 0
    error NotEnoughApartments();
    /// @notice When the provided target amount is 0
    error TargetAmountZero();
    /// @notice When the provided apartments and the prices array do not match in length
    error ApartmentsAvaibleDoesNotMatchPriceArray();
    /// @notice When the deadline has passed
    error DeadlineAlreadyPassed();
    /// @notice When the target fundrasing amount has already been collected
    error FundrasingTargetAmountAlreadyCollectedOrIsBeingExceeded();
    /// @notice When the deadline has not passed yet
    error DeadlineHasNotPassedYet();
    /// @notice When the target fundrasing amount has not been collected yet
    error TargetFundrasingAmountNotCollected();
    /// @notice When the call has not been successful
    error CallNotSuccessful();
    /// @notice When the funds have not been withdrawn yet
    error FundsNotWithdrawn();
    /// @notice When the apartment has already been bought
    error ApartmentAlreadyBought();
    /// @notice When the provided amount has been insufficient
    error InsufficientPaymentAmount();
    /// @notice When the funds have already been withdrawn
    error FundsAlreadyWithdrawn();
    /// @notice When the provided address is address(0)
    error AddressZero();
    /// @notice When the msg.sender is not the owner
    error NotOwner();
    /// @notice When not all apartments have been sold
    error NotAllApartmentsAreSold();
    /// @notice When user has not invested or has already claimed his rewards
    error NoRewardsToClaim();
    /// @notice When user has not invested and the targert fundrasing amount has not been met
    error NoInvestmentMade();
}
