// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @title Errors
/// @author YovchevYoan
/// @notice Library containing the errors
library Errors {
    /// @notice When the amount has been exceeded
    error AmountExceeds();
    /// @notice When the appartments provided are 0
    error NotEnoughAppartments();
    /// @notice When the provided target amount is 0
    error TargetAmountZero();
    /// @notice When the provided appartments and the prices array do not match in length
    error AppartmentsAvaibleDoesNotMatchPriceArray();
    /// @notice When the deadline has passed
    error DeadlineAlreadyPassed();
    /// @notice When the target fundrasing amount has already been collected
    error FundrasingTargetAmountAlreadyCollected();
    /// @notice When the deadline has not passed yet
    error DeadlineHasNotPassedYet();
    /// @notice When the target fundrasing amount has not been collected yet
    error TargetFundrasingAmountNotCollected();
    /// @notice When the call has not been successful
    error CallNotSuccessful();
    /// @notice When the funds have not been withdrawn yet
    error FundsNotWithdrawn();
    /// @notice When the appartment has already been bought
    error AppartmentAlreadyBought();
    /// @notice When the provided amount has been insufficient
    error InsufficientPaymentAmount();
    /// @notice When the funds have already been withdrawn
    error FundsAlreadyWithdrawn();
    /// @notice When the provided address is address(0)
    error AddressZero();
    /// @notice When the msg.sender is not the owner
    error NotOwner();
}
