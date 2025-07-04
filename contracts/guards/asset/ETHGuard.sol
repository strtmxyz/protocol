// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../../utils/TxDataUtils.sol";
import "../../interfaces/guards/IGuard.sol";
import "../../interfaces/IVault.sol";
import "../../interfaces/IHasSupportedAsset.sol";
import "../../interfaces/IHasGuardInfo.sol";
import "../../interfaces/guards/IAssetGuard.sol";
import "../../interfaces/IHasAssetInfo.sol";
import "../../interfaces/IWETH.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/*//////////////////////////////////////////////////////////////
                            CUSTOM ERRORS
//////////////////////////////////////////////////////////////*/

// Initialization errors
error InvalidWETHAddress();

// Transaction validation errors
error ETHAmountMustBeGreaterThanZero();
error InvalidTargetAddress();
error ETHGuardOnlySupportsNativeETH();

// Asset handling errors
error ETHGuardOnlyHandlesNativeETH();
error InvalidETHPrice();

/// @title ETHGuard - Guard for native ETH handling
/// @notice Handles native ETH operations and value calculations
contract ETHGuard is TxDataUtils, IGuard, IAssetGuard, Initializable {
    address public WETH;
    
    /// @notice Initialize the guard with WETH address
    /// @param _weth Address of the WETH contract
    function initialize(address _weth) public initializer {
        if (_weth == address(0)) revert InvalidWETHAddress();
        WETH = _weth;
    }

    /// @notice Guard transaction without native ETH (not implemented for ETH guard)
    function txGuard(address /*_vault*/, address /*_to*/, bytes calldata /*_data*/)
        public 
        pure 
        override 
        returns (uint16) 
    {
        revert ETHGuardOnlySupportsNativeETH();
    }

    /// @notice Guard transaction with native ETH amount
    /// @param _to Target contract address
    /// @param _nativeTokenAmount Amount of native ETH being sent
    /// @return txType Transaction type identifier
    function txGuard(address /*_vault*/, address _to, bytes calldata /*_data*/, uint256 _nativeTokenAmount)
        public 
        pure 
        override 
        returns (uint16 txType) 
    {
        // Basic validation for ETH transactions
        if (_nativeTokenAmount <= 0) revert ETHAmountMustBeGreaterThanZero();
        if (_to == address(0)) revert InvalidTargetAddress();
        
        // For now, allow all ETH transactions
        // Can be extended with specific ETH operation validation
        return 1; // ETH transfer type
    }

    /// @notice Get ETH balance of the vault
    /// @param vault Vault address
    /// @param asset Asset address (should be address(0) for native ETH)
    /// @return balance ETH balance in wei
    function getBalance(address vault, address asset) 
        public 
        view 
        virtual 
        override 
        returns (uint256 balance) 
    {
        if (asset == address(0)) {
            // Native ETH balance
            balance = address(vault).balance;
        } else {
            revert ETHGuardOnlyHandlesNativeETH();
        }
    }

    /// @notice Get decimals for ETH (18 decimals like WETH)
    /// @param asset Asset address (should be address(0) for native ETH)
    /// @return decimals Number of decimals (18 for ETH)
    function getDecimals(address asset) 
        external 
        view 
        virtual 
        override 
        returns (uint8 decimals) 
    {
        if (asset == address(0)) {
            // ETH has 18 decimals (same as WETH)
            decimals = 18;
        } else {
            revert ETHGuardOnlyHandlesNativeETH();
        }
    }

    /// @notice Calculate USD value of ETH amount
    /// @param vault Vault address
    /// @param asset Asset address (should be address(0) for native ETH)
    /// @param balance Amount of ETH in wei
    /// @return value USD value with proper decimals
    function calcValue(address vault, address asset, uint256 balance) 
        external 
        view 
        virtual 
        override 
        returns (uint256 value) 
    {
        if (asset != address(0)) revert ETHGuardOnlyHandlesNativeETH();
        
        address factory = IVault(vault).factory();
        value = _calculateETHValue(factory, balance);
    }

    /// @notice Calculate USD value of ETH amount using WETH price
    /// @param factory Factory address to get price from
    /// @param amount Amount of ETH in wei
    /// @return USD value with proper decimals
    function _calculateETHValue(address factory, uint256 amount) 
        internal 
        view 
        returns (uint256) 
    {
        // Use WETH price for ETH valuation (1:1 ratio)
        uint256 ethPriceUSD = IHasAssetInfo(factory).getAssetPrice(WETH);
        if (ethPriceUSD <= 0) revert InvalidETHPrice();
        
        // Calculate value: amount * price / 10^decimals
        // ETH has 18 decimals
        return (amount * ethPriceUSD) / (10 ** 18);
    }
}
