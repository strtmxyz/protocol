// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/*//////////////////////////////////////////////////////////////
                            INTERFACES
//////////////////////////////////////////////////////////////*/

/// @notice Interface for vault to mint shares
interface IVaultMinter {
    function mint(address to, uint256 shares) external;
    function convertToShares(uint256 assets) external view returns (uint256);
}

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
/// @notice Library for fee calculations and extractions with mint shares support
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

    event SharesMintedForFees(
        address indexed vault,
        address indexed manager,
        address indexed protocolTreasury,
        uint256 managerShares,
        uint256 protocolShares,
        uint256 totalFeeValue
    );

    /*//////////////////////////////////////////////////////////////
                           FEE CALCULATIONS
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Calculate management fees for new structure (protocol + manager)
    /// @param expectedValue Base value for fee calculation
    /// @param protocolFeeRate Protocol fee rate (basis points, fixed 50)
    /// @param managerFeeRate Manager fee rate (basis points, 0-200)
    /// @param timeElapsed Time elapsed since last calculation
    /// @param FEE_DENOMINATOR Fee denominator constant
    /// @return protocolManagementFee Protocol's management fee
    /// @return managerManagementFee Manager's management fee
    function calculateManagementFees(
        uint256 expectedValue,
        uint256 protocolFeeRate,
        uint256 managerFeeRate,
        uint256 timeElapsed,
        uint256 FEE_DENOMINATOR
    ) internal pure returns (uint256 protocolManagementFee, uint256 managerManagementFee) {
        // Protocol gets fixed rate from vault constants
        protocolManagementFee = (expectedValue * protocolFeeRate * timeElapsed) / (365 days * FEE_DENOMINATOR);
        // Manager gets 0-2% (0-200 basis points)
        managerManagementFee = (expectedValue * managerFeeRate * timeElapsed) / (365 days * FEE_DENOMINATOR);
    }
    
    /// @notice Calculate performance fees for new structure (manager + protocol)
    /// @param yield Realized yield amount
    /// @param managerPerformanceRate Manager performance fee rate (basis points, 1000)
    /// @param protocolPerformanceRate Protocol performance fee rate (basis points, 250)
    /// @param FEE_DENOMINATOR Fee denominator constant
    /// @return managerPerformanceFee Manager's performance fee
    /// @return protocolPerformanceFee Protocol's performance fee
    function calculatePerformanceFees(
        uint256 yield,
        uint256 managerPerformanceRate,
        uint256 protocolPerformanceRate,
        uint256 FEE_DENOMINATOR
    ) internal pure returns (uint256 managerPerformanceFee, uint256 protocolPerformanceFee) {
        // Manager gets rate from vault constants
        managerPerformanceFee = (yield * managerPerformanceRate) / FEE_DENOMINATOR;
        // Protocol gets rate from vault constants
        protocolPerformanceFee = (yield * protocolPerformanceRate) / FEE_DENOMINATOR;
    }
    
    /// @notice Calculate withdrawal fee (unchanged - still extract underlying)
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
                           SHARE CALCULATIONS
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Calculate shares to mint for fees
    /// @param totalFeeValue Total fee value in underlying asset terms
    /// @param currentSharePrice Current share price (assets per share)
    /// @return sharesToMint Number of shares to mint
    function calculateSharesToMint(
        uint256 totalFeeValue,
        uint256 currentSharePrice
    ) internal pure returns (uint256 sharesToMint) {
        if (currentSharePrice == 0) return 0;
        sharesToMint = (totalFeeValue * 1e18) / currentSharePrice;
    }
    
    /// @notice Calculate individual share allocations
    /// @param managerFeeValue Manager's fee value
    /// @param protocolFeeValue Protocol's fee value
    /// @param currentSharePrice Current share price
    /// @return managerShares Shares to mint for manager
    /// @return protocolShares Shares to mint for protocol
    function calculateFeeShares(
        uint256 managerFeeValue,
        uint256 protocolFeeValue,
        uint256 currentSharePrice
    ) internal pure returns (uint256 managerShares, uint256 protocolShares) {
        if (currentSharePrice == 0) return (0, 0);
        
        managerShares = (managerFeeValue * 1e18) / currentSharePrice;
        protocolShares = (protocolFeeValue * 1e18) / currentSharePrice;
    }

    /*//////////////////////////////////////////////////////////////
                           FEE VALIDATION
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Validate fee rates for new structure
    /// @param managerFee Manager management fee rate (0-200 basis points)
    /// @param withdrawalFee Withdrawal fee rate (0-100 basis points)
    function validateFeeRates(
        uint256 managerFee,
        uint256 withdrawalFee
    ) internal pure {
        // Manager management fee: 0-2% (0-200 basis points)
        if (managerFee > 200) revert ManagementFeeTooHigh();
        // Withdrawal fee: 0-1% (0-100 basis points)
        if (withdrawalFee > 100) revert WithdrawalFeeTooHigh();
    }

    /*//////////////////////////////////////////////////////////////
                           MINT SHARES FOR FEES
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Mint shares for management and performance fees
    /// @param vault Vault address (must implement IVaultMinter)
    /// @param manager Manager address
    /// @param protocolTreasury Protocol treasury address
    /// @param managerFeeValue Manager's total fee value
    /// @param protocolFeeValue Protocol's total fee value
    /// @param currentSharePrice Current share price
    function mintSharesForFees(
        address vault,
        address manager,
        address protocolTreasury,
        uint256 managerFeeValue,
        uint256 protocolFeeValue,
        uint256 currentSharePrice
    ) internal {
        if (managerFeeValue == 0 && protocolFeeValue == 0) return;
        
        (uint256 managerShares, uint256 protocolShares) = calculateFeeShares(
            managerFeeValue,
            protocolFeeValue,
            currentSharePrice
        );
        
        IVaultMinter vaultMinter = IVaultMinter(vault);
        
        // Mint shares for manager
        if (managerShares > 0) {
            vaultMinter.mint(manager, managerShares);
        }
        
        // Mint shares for protocol
        if (protocolShares > 0 && protocolTreasury != address(0)) {
            vaultMinter.mint(protocolTreasury, protocolShares);
        }
        
        emit SharesMintedForFees(
            vault,
            manager,
            protocolTreasury,
            managerShares,
            protocolShares,
            managerFeeValue + protocolFeeValue
        );
    }

    /*//////////////////////////////////////////////////////////////
                           FEE EXTRACTION (LEGACY)
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Extract fees from underlying asset (legacy method)
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
    
    /// @notice Extract withdrawal fee and transfer to manager (unchanged)
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
    
    /// @notice Calculate expected management fees over time period for new structure
    /// @param vaultValue Current vault value
    /// @param managerFeeRate Manager fee rate
    /// @param timeElapsed Time period
    /// @param FEE_DENOMINATOR Fee denominator
    /// @return protocolFee Expected protocol management fee
    /// @return managerFee Expected manager management fee
    function previewManagementFees(
        uint256 vaultValue,
        uint256 managerFeeRate,
        uint256 timeElapsed,
        uint256 FEE_DENOMINATOR
    ) internal pure returns (uint256 protocolFee, uint256 managerFee) {
        return calculateManagementFees(vaultValue, 50, managerFeeRate, timeElapsed, FEE_DENOMINATOR);
    }
    
    /// @notice Preview performance fees for new structure
    /// @param yield Realized yield amount
    /// @param FEE_DENOMINATOR Fee denominator
    /// @return managerFee Expected manager performance fee
    /// @return protocolFee Expected protocol performance fee
    function previewPerformanceFees(
        uint256 yield,
        uint256 FEE_DENOMINATOR
    ) internal pure returns (uint256 managerFee, uint256 protocolFee) {
        return calculatePerformanceFees(yield, 1000, 250, FEE_DENOMINATOR);
    }
} 