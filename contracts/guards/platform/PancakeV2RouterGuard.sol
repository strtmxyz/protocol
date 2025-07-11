// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../interfaces/guards/IPlatformGuard.sol";
import "../../utils/TxDataUtils.sol";
import "../../interfaces/IHasSupportedAsset.sol";
import "../../interfaces/ITransactionTypes.sol";
import "../../interfaces/external/pancakeswap/IPancakeV2Router.sol";
import "../../interfaces/external/pancakeswap/IPancakeV2Factory.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/*//////////////////////////////////////////////////////////////
                            CUSTOM ERRORS
//////////////////////////////////////////////////////////////*/

// Asset validation errors
error UnsupportedDestinationAsset();
error UnsupportedSourceAsset();

// Transaction validation errors
error RecipientIsNotVault();
error ExpiredDeadline();
error PayableAmountMustBeGreaterThanZero();

// Liquidity validation errors
error InvalidPair();

/// @title PancakeSwap V2 Router Guard
/// @notice Transaction guard for PancakeSwap V2 Router operations
/// @dev Validates swap and liquidity operations against vault policies
contract PancakeV2RouterGuard is TxDataUtils, IPlatformGuard, ITransactionTypes, Initializable {
    string public override platformName;
    
    /// @notice Initialize the guard with platform name
    function initialize() public initializer {
        platformName = "PancakeV2RouterGuard";
    }

    /// @notice Guard for non-payable transactions
    /// @param _vault The vault address initiating the transaction
    /// @param _to The target contract address (router)
    /// @param _data The transaction data
    /// @return txType The type of transaction (Exchange)
    function txGuard(address _vault, address _to, bytes memory _data)
        public override returns (uint16 txType)
    {
        bytes4 method = getMethod(_data);
        
        // Handle exact tokens for tokens swap
        if (method == IPancakeV2Router.swapExactTokensForTokens.selector) {
            (uint256 amountIn, uint256 amountOutMin, address[] memory path, address to, uint256 deadline) = 
                abi.decode(getParams(_data), (uint256, uint256, address[], address, uint256));
            
            _validateDeadline(deadline);
            _validateRecipient(_vault, to);
            _validateDestinationAsset(_vault, path[path.length - 1]);
            
            emit ExchangeFrom(_vault, _to, path[0], amountIn, path[path.length - 1]);
            txType = uint16(TransactionType.Exchange);
        }
        // Handle tokens for exact tokens swap  
        else if (method == IPancakeV2Router.swapTokensForExactTokens.selector) {
            (uint256 amountOut, uint256 amountInMax, address[] memory path, address to, uint256 deadline) = 
                abi.decode(getParams(_data), (uint256, uint256, address[], address, uint256));
            
            _validateDeadline(deadline);
            _validateRecipient(_vault, to);
            _validateDestinationAsset(_vault, path[path.length - 1]);
            
            emit ExchangeFrom(_vault, _to, path[0], amountInMax, path[path.length - 1]);
            txType = uint16(TransactionType.Exchange);
        }
        // Handle add liquidity operation
        else if (method == IPancakeV2Router.addLiquidity.selector) {
            (address tokenA, address tokenB, , , , , address to, uint256 deadline) = 
                abi.decode(getParams(_data), (address, address, uint256, uint256, uint256, uint256, address, uint256));
            
            _validateDeadline(deadline);
            _validateRecipient(_vault, to);
            _validatePair(_vault, _to, tokenA, tokenB);
            
            emit ExchangeFrom(_vault, _to, tokenA, 0, tokenB);
            txType = uint16(TransactionType.Exchange);
        }
        // Handle remove liquidity operation
        else if (method == IPancakeV2Router.removeLiquidity.selector) {
            (address tokenA, address tokenB, uint256 liquidity, , , address to, uint256 deadline) = 
                abi.decode(getParams(_data), (address, address, uint256, uint256, uint256, address, uint256));
            
            _validateDeadline(deadline);
            _validateRecipient(_vault, to);
            _validateDestinationAsset(_vault, tokenA);
            _validateDestinationAsset(_vault, tokenB);
            _validatePair(_vault, _to, tokenA, tokenB);
            
            emit ExchangeFrom(_vault, _to, address(0), liquidity, tokenA);
            txType = uint16(TransactionType.Exchange);
        }
        
        return txType;
    }

    function txGuard(address _vault, address _to, bytes memory _data, uint256 _nativeTokenAmount)
        public override returns (uint16 txType)
    {
        if (_nativeTokenAmount <= 0) revert PayableAmountMustBeGreaterThanZero();
        if (!IHasSupportedAsset(_vault).isSupportedAsset(address(0))) revert UnsupportedSourceAsset();
        
        bytes4 method = getMethod(_data);
        
        // V2 Router không có ETH functions, vì vậy không support payable calls
        // Nếu cần ETH swap thì phải dùng WETH wrapper trước
        
        return txType;
    }
    
    /*//////////////////////////////////////////////////////////////
                            VALIDATION HELPERS
    //////////////////////////////////////////////////////////////*/
    
    function _validateDeadline(uint256 _deadline) internal view {
        if (_deadline < block.timestamp) revert ExpiredDeadline();
    }
    
    function _validateRecipient(address _vault, address _recipient) internal pure {
        if (_vault != _recipient) revert RecipientIsNotVault();
    }
    
    function _validateDestinationAsset(address _vault, address _asset) internal view {
        if (!IHasSupportedAsset(_vault).isSupportedAsset(_asset)) revert UnsupportedDestinationAsset();
    }
    
    function _validatePair(address _vault, address _router, address _tokenA, address _tokenB) internal view {
        address pair = IPancakeV2Factory(IPancakeV2Router(_router).factory()).getPair(_tokenA, _tokenB);
        if (pair == address(0)) revert InvalidPair();
        if (!IHasSupportedAsset(_vault).isSupportedAsset(pair)) revert UnsupportedDestinationAsset();
    }
} 