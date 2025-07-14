// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../../interfaces/guards/IPlatformGuard.sol";
import "../../utils/TxDataUtils.sol";
import "../../interfaces/IHasSupportedAsset.sol";
import "../../interfaces/IVault.sol";
import "../../interfaces/ITransactionTypes.sol";
import "../../interfaces/external/ambient/ICrocSwapDex.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/*//////////////////////////////////////////////////////////////
                            CUSTOM ERRORS
//////////////////////////////////////////////////////////////*/

// Asset validation errors
error UnsupportedDestinationAsset();
error UnsupportedSourceAsset();

// Transaction validation errors
error RecipientIsNotVault();
error PayableAmountMustBeGreaterThanZero();
error UnsupportedCallpath();
error InsufficientNativeTokenAmount();

/// @title AmbientGuard
/// @notice Guard for Ambient Finance (formerly CrocSwap) protocol
/// @dev Validates userCmd calls to ensure they are safe for vault operations
contract AmbientGuard is TxDataUtils, IPlatformGuard, ITransactionTypes, Initializable {

    string public override platformName;
    
    // Supported callpaths for Ambient Finance
    // Only support swap operations for now
    uint16 public constant SWAP_PROXY_IDX = 1;
    // Not Used
    uint16 public constant FLAT_LP_PROXY_IDX = 2;
    // Not Used
    uint16 public constant KNOCKOUT_LP_V2_PROXY_IDX = 7;

    function initialize() public initializer {
        platformName = "AmbientGuard";
    }

    /// @notice Validates userCmd calls to Ambient protocol
    /// @param _vault The vault making the call
    /// @param _to The Ambient contract address
    /// @param _data The call data containing userCmd
    /// @return txType The type of transaction
    function txGuard(address _vault, address _to, bytes memory _data)
        public override returns (uint16 txType)
    {
        bytes4 method = getMethod(_data);

        if (method == ICrocSwapDex.userCmd.selector) {
            (uint16 callpath, bytes memory cmd) = abi.decode(getParams(_data), (uint16, bytes));
            
            // Only support swap operations
            if (callpath != SWAP_PROXY_IDX) revert UnsupportedCallpath();
            
            _handleSwapCallpath(_vault, _to, cmd, 0);
            txType = uint16(TransactionType.Exchange);
        }

        return txType;
    }

    /// @notice Validates userCmd calls with ETH value
    /// @param _vault The vault making the call
    /// @param _to The Ambient contract address
    /// @param _data The call data containing userCmd
    /// @param _nativeTokenAmount The ETH amount being sent
    /// @return txType The type of transaction
    function txGuard(address _vault, address _to, bytes memory _data, uint256 _nativeTokenAmount)
        public override returns (uint16 txType)
    {
        if (_nativeTokenAmount <= 0) revert PayableAmountMustBeGreaterThanZero();

        bytes4 method = getMethod(_data);

        if (method == ICrocSwapDex.userCmd.selector) {
            (uint16 callpath, bytes memory cmd) = abi.decode(getParams(_data), (uint16, bytes));
            
            // Only support swap operations
            if (callpath != SWAP_PROXY_IDX) revert UnsupportedCallpath();
            
            _handleSwapCallpath(_vault, _to, cmd, _nativeTokenAmount);
            txType = uint16(TransactionType.Exchange);
        }

        return txType;
    }

    function _handleSwapCallpath(address _vault, address _to, bytes memory cmd, uint256 _nativeTokenAmount) internal {
        // Parse cmd data according to Ambient's swap command structure
        // Based on real transaction analysis from Monad testnet
        
        // Extract base token address (chunk 0)
        address baseToken;
        assembly {
            baseToken := mload(add(cmd, 32))  // Chunk 0: base token
        }
        
        // Extract quote token address (chunk 1) 
        address quoteToken;
        assembly {
            quoteToken := mload(add(cmd, 64))  // Chunk 1: quote token
        }
        
        // Extract quantity (chunk 5) - bytes 160-192
        uint256 qty;
        assembly {
            qty := mload(add(cmd, 192))  // Chunk 5: quantity
        }
        
        // Extract swap params (chunk 7) - bytes 224-256
        uint256 swapParams;
        assembly {
            swapParams := mload(add(cmd, 256))  // Chunk 7: contains isBuy + other flags
        }
        
        // Determine swap direction from cmd data
        // swapParams contains packed data including isBuy flag
        bool isBuy = (swapParams & 0x1) == 1;
        
        // Determine source and destination tokens based on swap direction
        address sourceToken;
        address destToken;
        
        if (isBuy) {
            // Buying base with quote
            sourceToken = quoteToken;  // Paying with quote token
            destToken = baseToken;     // Receiving base token
        } else {
            // Selling base for quote  
            sourceToken = baseToken;   // Paying with base token
            destToken = quoteToken;    // Receiving quote token
        }
        
        // Additional validation for ETH transactions
        address NATIVE_TOKEN_ADDRESS = address(0);
        if (sourceToken == NATIVE_TOKEN_ADDRESS) {
            // If source token is ETH, verify sufficient native token amount
            if (_nativeTokenAmount < qty) {
                revert InsufficientNativeTokenAmount();
            }
        }
        
        // Validate both tokens are supported by vault
        IHasSupportedAsset supportedAsset = IHasSupportedAsset(_vault);
        
        // Source token validation (token being spent)
        if (!supportedAsset.isSupportedAsset(sourceToken)) {
            revert UnsupportedSourceAsset();
        }
        
        // Destination token validation (token being received)
        if (!supportedAsset.isSupportedAsset(destToken)) {
            revert UnsupportedDestinationAsset();
        }
        
        // Emit event with actual swap data
        emit ExchangeFrom(_vault, _to, sourceToken, qty, destToken);
    }
}