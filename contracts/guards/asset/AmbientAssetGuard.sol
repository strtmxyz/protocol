// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../../utils/TxDataUtils.sol";
import "../../interfaces/guards/IGuard.sol";
import "../../interfaces/IVault.sol";
import "../../interfaces/IHasSupportedAsset.sol";
import "../../interfaces/IHasGuardInfo.sol";
import "../../interfaces/guards/IAssetGuard.sol";
import "../../interfaces/IHasAssetInfo.sol";
import "../../interfaces/external/ambient/ICrocQuery.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/*//////////////////////////////////////////////////////////////
                            CUSTOM ERRORS
//////////////////////////////////////////////////////////////*/

error InvalidEndpointAddress();
error NotImplemented();
error UnsupportedAsset();

/// @title AmbientAssetGuard
/// @notice Asset guard for Ambient Finance liquidity positions
/// @dev Handles ambient liquidity tokens and position calculations
contract AmbientAssetGuard is TxDataUtils, IGuard, IAssetGuard, Initializable {

    address public crocQueryEndpoint;
    
    // Mapping to store base-quote pair configurations for ambient positions
    mapping(address => mapping(address => uint256)) public poolConfigs; // asset => quote => poolIdx

    /// @notice Initialize the guard with crocQueryEndpoint address
    /// @param _crocQueryEndpoint Address of the CrocQuery contract
    function initialize(address _crocQueryEndpoint) public initializer {
        if (_crocQueryEndpoint == address(0)) revert InvalidEndpointAddress();
        crocQueryEndpoint = _crocQueryEndpoint;
    }

    /// @notice Guard transaction without native ETH 
    /// @return txType Transaction type identifier
    function txGuard(address /*_vault*/, address /*_to*/, bytes calldata /*_data*/)
        public 
        pure 
        override 
        returns (uint16) 
    {
        revert NotImplemented();
    }

    /// @notice Guard transaction with native ETH amount
    /// @return txType Transaction type identifier
    function txGuard(address /*_vault*/, address /*_to*/, bytes calldata /*_data*/, uint256 /*nativeTokenAmount*/)
        public 
        pure 
        override 
        returns (uint16 /*txType*/) 
    {
        revert NotImplemented();
    }

    /// @notice Get ambient liquidity position balance
    /// @param vault Vault address (position owner)
    /// @param asset Asset address (base token of the pair)
    /// @return balance Position balance (seeds or liquidity amount)
    function getBalance(address vault, address asset) 
        public 
        view 
        virtual 
        override 
        returns (uint256 balance) 
    {
        // For now, return 0 as this needs proper pool configuration
        // In real implementation, should query ambient position for the vault
        return 0;
    }

    /// @notice Get decimals for ambient position tokens (standardized to 18)
    /// @return decimals Number of decimals (18 for ambient positions)
    function getDecimals(address /*asset*/) 
        external 
        pure 
        virtual 
        override 
        returns (uint8 decimals) 
    {
        // Ambient positions use 18 decimals for liquidity calculations
        return 18;
    }

    /// @notice Calculate USD value of ambient position
    /// @param vault Vault address (position owner)
    /// @param asset Asset address (base token)
    /// @param balance Position balance amount
    /// @return value USD value of the position
    function calcValue(address vault, address asset, uint256 balance) 
        external 
        view 
        virtual 
        override 
        returns (uint256 value) 
    {
        // For now, return 0 as this needs proper implementation
        // In real implementation, should:
        // 1. Get the quote token for this asset
        // 2. Query ambient position tokens
        // 3. Calculate total USD value based on both token amounts
        return 0;
    }

    /// @notice Set pool configuration for an asset pair
    /// @param baseAsset Base token address
    /// @param quoteAsset Quote token address  
    /// @param poolIdx Pool index for the pair
    function setPoolConfig(address baseAsset, address quoteAsset, uint256 poolIdx) external {
        // Should add access control (onlyOwner or similar)
        poolConfigs[baseAsset][quoteAsset] = poolIdx;
    }

    /// @notice Get range position tokens for a vault
    /// @param vault Vault address
    /// @param baseAsset Base token address
    /// @param quoteAsset Quote token address
    /// @param bidTick Lower tick of the range
    /// @param askTick Upper tick of the range
    /// @return liq Liquidity amount
    /// @return baseQty Base token quantity
    /// @return quoteQty Quote token quantity
    function getRangeTokens(address vault, address baseAsset, address quoteAsset, int24 bidTick, int24 askTick) 
        external 
        view 
        returns (uint128 liq, uint128 baseQty, uint128 quoteQty) 
    {
        uint256 poolIdx = poolConfigs[baseAsset][quoteAsset];
        if (poolIdx == 0) revert UnsupportedAsset();
        
        return ICrocQuery(crocQueryEndpoint).queryRangeTokens(vault, baseAsset, quoteAsset, poolIdx, bidTick, askTick);
    }
}
