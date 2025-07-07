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

    /*//////////////////////////////////////////////////////////////
                        TIME-BASED WITHDRAWAL FEES
    //////////////////////////////////////////////////////////////*/
    
    /// @notice User deposit tracking struct
    struct UserDeposit {
        uint256 amount;
        uint256 timestamp;
    }
    
    /// @notice Calculate time-based withdrawal fee for a user
    /// @param deposits User's deposit history
    /// @param assets Amount of assets to withdraw
    /// @param shortTermFee Fee for < 30 days (basis points)
    /// @param mediumTermFee Fee for 30 days - 6 months (basis points)
    /// @param longTermFee Fee for > 6 months (basis points)
    /// @param defaultFee Default withdrawal fee (basis points)
    /// @param FEE_DENOMINATOR Fee denominator constant
    /// @return fee Time-based withdrawal fee
    function calculateTimedWithdrawalFee(
        UserDeposit[] memory deposits,
        uint256 assets,
        uint256 shortTermFee,
        uint256 mediumTermFee,
        uint256 longTermFee,
        uint256 defaultFee,
        uint256 FEE_DENOMINATOR
    ) internal view returns (uint256 fee) {
        if (deposits.length == 0) {
            // No deposits tracked, use default fee
            return calculateWithdrawalFee(assets, defaultFee, FEE_DENOMINATOR);
        }
        
        uint256 totalWithdrawAmount = assets;
        uint256 totalFee = 0;
        
        // Process deposits in FIFO order (oldest first)
        for (uint256 i = 0; i < deposits.length && totalWithdrawAmount > 0; i++) {
            UserDeposit memory deposit = deposits[i];
            if (deposit.amount == 0) continue;
            
            uint256 withdrawFromDeposit = totalWithdrawAmount > deposit.amount ? deposit.amount : totalWithdrawAmount;
            uint256 feeRate = _getFeeRateForDeposit(
                deposit.timestamp,
                shortTermFee,
                mediumTermFee,
                longTermFee
            );
            
            totalFee += calculateWithdrawalFee(withdrawFromDeposit, feeRate, FEE_DENOMINATOR);
            totalWithdrawAmount -= withdrawFromDeposit;
        }
        
        // If there's remaining amount after all deposits, use default fee
        if (totalWithdrawAmount > 0) {
            totalFee += calculateWithdrawalFee(totalWithdrawAmount, defaultFee, FEE_DENOMINATOR);
        }
        
        return totalFee;
    }
    
    /// @notice Get fee rate based on deposit timestamp
    /// @param depositTimestamp Timestamp of the deposit
    /// @param shortTermFee Fee for < 30 days (basis points)
    /// @param mediumTermFee Fee for 30 days - 6 months (basis points)
    /// @param longTermFee Fee for > 6 months (basis points)
    /// @return feeRate Fee rate in basis points
    function _getFeeRateForDeposit(
        uint256 depositTimestamp,
        uint256 shortTermFee,
        uint256 mediumTermFee,
        uint256 longTermFee
    ) internal view returns (uint256 feeRate) {
        uint256 holdingPeriod = block.timestamp - depositTimestamp;
        
        if (holdingPeriod < 30 days) {
            return shortTermFee; // < 30 days
        } else if (holdingPeriod < 180 days) {
            return mediumTermFee; // 30 days - 6 months
        } else {
            return longTermFee; // > 6 months
        }
    }
    
    /// @notice Update user deposits after withdrawal (FIFO basis)
    /// @param deposits Storage reference to user deposits
    /// @param assets Amount of assets withdrawn
    /// @param userTotalDeposited Storage reference to user total deposited
    function updateUserDepositsAfterWithdraw(
        UserDeposit[] storage deposits,
        uint256 assets,
        uint256 userTotalDeposited
    ) internal returns (uint256 newTotalDeposited) {
        uint256 remainingWithdraw = assets;
        newTotalDeposited = userTotalDeposited;
        
        // Process deposits in FIFO order
        for (uint256 i = 0; i < deposits.length && remainingWithdraw > 0; i++) {
            UserDeposit storage deposit = deposits[i];
            if (deposit.amount == 0) continue;
            
            if (deposit.amount <= remainingWithdraw) {
                // Fully consume this deposit
                remainingWithdraw -= deposit.amount;
                newTotalDeposited -= deposit.amount;
                deposit.amount = 0;
            } else {
                // Partially consume this deposit
                deposit.amount -= remainingWithdraw;
                newTotalDeposited -= remainingWithdraw;
                remainingWithdraw = 0;
            }
        }
        
        return newTotalDeposited;
    }
    
    /// @notice Calculate user's average holding period
    /// @param deposits User's deposit history
    /// @return avgHoldingPeriod Average holding period in seconds
    function calculateUserAverageHoldingPeriod(
        UserDeposit[] memory deposits
    ) internal view returns (uint256 avgHoldingPeriod) {
        if (deposits.length == 0) return 0;
        
        uint256 totalWeightedTime = 0;
        uint256 totalAmount = 0;
        
        for (uint256 i = 0; i < deposits.length; i++) {
            if (deposits[i].amount > 0) {
                uint256 holdingPeriod = block.timestamp - deposits[i].timestamp;
                totalWeightedTime += deposits[i].amount * holdingPeriod;
                totalAmount += deposits[i].amount;
            }
        }
        
        return totalAmount > 0 ? totalWeightedTime / totalAmount : 0;
    }
    
    /// @notice Validate time-based withdrawal fee structure
    /// @param shortTermFee Short term fee rate
    /// @param mediumTermFee Medium term fee rate
    /// @param longTermFee Long term fee rate
    /// @param MAX_FEE Maximum allowed fee rate
    function validateTimedWithdrawalFeeStructure(
        uint256 shortTermFee,
        uint256 mediumTermFee,
        uint256 longTermFee,
        uint256 MAX_FEE
    ) internal pure {
        if (shortTermFee > MAX_FEE || mediumTermFee > MAX_FEE || longTermFee > MAX_FEE) {
            revert WithdrawalFeeTooHigh();
        }
        
        // Ensure fee structure makes sense (should decrease with time)
        if (shortTermFee < mediumTermFee || mediumTermFee < longTermFee) {
            revert WithdrawalFeeTooHigh();
        }
    }
} 