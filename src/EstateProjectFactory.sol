// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {EstateProject} from "./EstateProject.sol";

/// @title EstateProjectFactory
/// @author YovchevYoan
/// @notice Factory contract responsible for creating EstateProject contracts
/// @dev Includes a mapping with all the estate projects - past and present
contract EstateProjectFactory {
    /// @notice An array of the real estate projects
    EstateProject[] public s_estateProjects;

    /// @notice Emitted when a new EstateProject has been created
    /// @param initialOwner The initial owner of the EstateProject
    /// @param estateProject The EstateProjects
    event EstateProjectCreated(
        address indexed initialOwner,
        EstateProject indexed estateProject
    );

    /// @notice Check EstateProject.sol
    function createEstateProject(
        string memory name,
        string memory symbol,
        string memory location,
        uint256 deadline,
        uint256 apartmentsAvailable,
        uint256 targetFundrasingAmount,
        uint256[] memory apartmentPrices
    ) public returns (EstateProject estateProject) {
        estateProject = new EstateProject({
            name: name,
            symbol: symbol,
            location: location,
            deadline: deadline,
            apartmentsAvailable: apartmentsAvailable,
            targetFundrasingAmount: targetFundrasingAmount,
            apartmentsPrices: apartmentPrices
        });

        s_estateProjects.push(estateProject);

        emit EstateProjectCreated(msg.sender, estateProject);
    }

    /// @notice Helper function returning the length of the estate projects array
    function getEstateProjectArrayLength() external view returns (uint256) {
        return s_estateProjects.length;
    }
}
