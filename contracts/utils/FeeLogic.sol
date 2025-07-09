// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/*//////////////////////////////////////////////////////////////
                            CUSTOM ERRORS
//////////////////////////////////////////////////////////////*/

// Fee validation errors
error ManagementFeeTooHigh();
error PerformanceFeeTooHigh();
error WithdrawalFeeTooHigh();
error ProtocolFeeTooHigh();

// Fee extraction errors
error InsufficientUnderlyingBalanceForFees();

/// @title FeeLogic
/// @notice Library for fee calculations and extractions
library FeeLogic {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                              EVENTS
    //////////////////////////////////////////////////////////////*/
    
    event FeesExtracted(
        address indexed vault,
        address indexed manager,
        address indexed protocolTreasury,
        uint256 managementFee,
        uint256 managerPerformanceFee,
        uint256 protocolFee
    );

    /*//////////////////////////////////////////////////////////////
                           FEE CALCULATIONS
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Calculate management fee based on time elapsed
    /// @param expectedValue Base value for fee calculation
    /// @param managementFeeRate Management fee rate (basis points)
    /// @param timeElapsed Time elapsed since last calculation
    /// @param FEE_DENOMINATOR Fee denominator constant
    /// @return Management fee amount
    function calculateManagementFee(
        uint256 expectedValue,
        uint256 managementFeeRate,
        uint256 timeElapsed,
        uint256 FEE_DENOMINATOR
    ) internal pure returns (uint256) {
        return (expectedValue * managementFeeRate * timeElapsed) / (365 days * FEE_DENOMINATOR);
    }
    
    /// @notice Calculate performance fees
    /// @param yield Realized yield amount
    /// @param performanceFeeRate Performance fee rate (basis points)
    /// @param protocolFeeRate Protocol fee rate (basis points of performance fee)
    /// @param FEE_DENOMINATOR Fee denominator constant
    /// @return managerPerformanceFee Manager's share
    /// @return protocolFeeAmount Protocol's share
    function calculatePerformanceFees(
        uint256 yield,
        uint256 performanceFeeRate,
        uint256 protocolFeeRate,
        uint256 FEE_DENOMINATOR
    ) internal pure returns (uint256 managerPerformanceFee, uint256 protocolFeeAmount) {
        uint256 totalPerformanceFee = (yield * performanceFeeRate) / FEE_DENOMINATOR;
        protocolFeeAmount = (totalPerformanceFee * protocolFeeRate) / FEE_DENOMINATOR;
        managerPerformanceFee = totalPerformanceFee - protocolFeeAmount;
    }
    
    /// @notice Calculate withdrawal fee
    /// @param assets Amount to withdraw
    /// @param withdrawalFeeRate Withdrawal fee rate (basis points)
    /// @param FEE_DENOMINATOR Fee denominator constant
    /// @return Withdrawal fee amount
    function calculateWithdrawalFee(
        uint256 assets,
        uint256 withdrawalFeeRate,
        uint256 FEE_DENOMINATOR
    ) internal pure returns (uint256) {
        return (assets * withdrawalFeeRate) / FEE_DENOMINATOR;
    }

    /*//////////////////////////////////////////////////////////////
                           FEE VALIDATION
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Validate fee rates are within acceptable limits
    /// @param managementFee Management fee rate
    /// @param performanceFee Performance fee rate
    /// @param withdrawalFee Withdrawal fee rate
    /// @param protocolFee Protocol fee rate
    /// @param MAX_FEE Maximum allowed fee rate
    /// @param MAX_PROTOCOL_FEE Maximum protocol fee share
    function validateFeeRates(
        uint256 managementFee,
        uint256 performanceFee,
        uint256 withdrawalFee,
        uint256 protocolFee,
        uint256 MAX_FEE,
        uint256 MAX_PROTOCOL_FEE
    ) internal pure {
        if (managementFee > MAX_FEE) revert ManagementFeeTooHigh();
        if (performanceFee > MAX_FEE) revert PerformanceFeeTooHigh();
        if (withdrawalFee > MAX_FEE) revert WithdrawalFeeTooHigh();
        if (protocolFee > MAX_PROTOCOL_FEE) revert ProtocolFeeTooHigh();
    }

    /*//////////////////////////////////////////////////////////////
                           FEE EXTRACTION
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Extract fees from underlying asset
    /// @param asset Underlying asset address
    /// @param vault Vault address (for balance check)
    /// @param manager Manager address
    /// @param protocolTreasury Protocol treasury address
    /// @param managementFeeAmount Management fee amount
    /// @param managerPerformanceFee Manager's performance fee
    /// @param protocolFeeAmount Protocol fee amount
    function extractFeesFromUnderlying(
        address asset,
        address vault,
        address manager,
        address protocolTreasury,
        uint256 managementFeeAmount,
        uint256 managerPerformanceFee,
        uint256 protocolFeeAmount
    ) internal {
        uint256 totalFees = managementFeeAmount + managerPerformanceFee + protocolFeeAmount;
        uint256 underlyingBalance = IERC20(asset).balanceOf(vault);
        
        if (underlyingBalance < totalFees) revert InsufficientUnderlyingBalanceForFees();
        
        uint256 managerFees = managementFeeAmount + managerPerformanceFee;
        
        // Transfer fees to manager
        if (managerFees > 0) {
            IERC20(asset).safeTransfer(manager, managerFees);
        }
        
        // Transfer protocol fee to treasury
        if (protocolFeeAmount > 0 && protocolTreasury != address(0)) {
            IERC20(asset).safeTransfer(protocolTreasury, protocolFeeAmount);
        }
        
        emit FeesExtracted(
            vault,
            manager,
            protocolTreasury,
            managementFeeAmount,
            managerPerformanceFee,
            protocolFeeAmount
        );
    }

    /*//////////////////////////////////////////////////////////////
                           WITHDRAWAL FEE EXTRACTION
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Extract withdrawal fee and transfer to manager
    /// @param asset Asset address
    /// @param manager Manager address
    /// @param withdrawalFeeAmount Fee amount to extract
    function extractWithdrawalFee(
        address asset,
        address manager,
        uint256 withdrawalFeeAmount
    ) internal {
        if (withdrawalFeeAmount > 0) {
            IERC20(asset).safeTransfer(manager, withdrawalFeeAmount);
        }
    }

    /*//////////////////////////////////////////////////////////////
                           FEE PREVIEW CALCULATIONS
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Preview withdrawal impact including fees
    /// @param assets Amount to withdraw
    /// @param withdrawalFeeRate Withdrawal fee rate
    /// @param FEE_DENOMINATOR Fee denominator
    /// @return assetsWithFee Total amount including fees
    /// @return feeAmount Fee amount
    function previewWithdrawalFees(
        uint256 assets,
        uint256 withdrawalFeeRate,
        uint256 FEE_DENOMINATOR
    ) internal pure returns (uint256 assetsWithFee, uint256 feeAmount) {
        feeAmount = calculateWithdrawalFee(assets, withdrawalFeeRate, FEE_DENOMINATOR);
        assetsWithFee = assets + feeAmount;
    }
    
    /// @notice Calculate expected management fees over time period
    /// @param vaultValue Current vault value
    /// @param managementFeeRate Management fee rate
    /// @param timeElapsed Time period
    /// @param FEE_DENOMINATOR Fee denominator
    /// @return Expected management fee
    function previewManagementFees(
        uint256 vaultValue,
        uint256 managementFeeRate,
        uint256 timeElapsed,
        uint256 FEE_DENOMINATOR
    ) internal pure returns (uint256) {
        return calculateManagementFee(vaultValue, managementFeeRate, timeElapsed, FEE_DENOMINATOR);
    }
} 