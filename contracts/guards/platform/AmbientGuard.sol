// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../interfaces/guards/IPlatformGuard.sol";
import "../../utils/TxDataUtils.sol";
import "../../interfaces/IHasSupportedAsset.sol";
import "../../interfaces/IVault.sol";
import "../../interfaces/ITransactionTypes.sol";
import "../../interfaces/external/ambient/ICrocSwapDex.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
 * @title AmbientGuardFix
 * @notice Improved version of AmbientGuard (CrocSwap) to handle both ERC20 and Native Token transactions
 * @dev Validates userCmd calls to ensure they are safe for vault operations
 */
contract AmbientGuard is TxDataUtils, IPlatformGuard, ITransactionTypes, Initializable {
    // Custom errors for asset validation
    error UnsupportedDestinationAsset(address asset);
    error UnsupportedSourceAsset(address asset);
    
    // Custom errors for transaction validation
    error PayableAmountMustBeGreaterThanZero();
    error UnsupportedCallpath(uint16 callpath);
    error InsufficientNativeTokenAmount(uint256 required, uint256 provided);
    
    string public override platformName;
    
    // Supported callpaths for Ambient Finance
    uint16 public constant SWAP_PROXY_IDX = 1;
    uint16 public constant FLAT_LP_PROXY_IDX = 2;
    uint16 public constant KNOCKOUT_LP_V2_PROXY_IDX = 7;
    
    // Native token address constant
    address public constant NATIVE_TOKEN_ADDRESS = address(0);
    
    // Special identifier for Native Token in CrocSwap
    uint256 public constant NATIVE_TOKEN_ID = 2;

    /**
     * @notice Initialize the contract
     * @dev Sets the platform name
     */
    function initialize() external initializer {
        platformName = "AmbientGuard";
    }

    /**
     * @notice Validates userCmd calls to Ambient protocol
     * @param _vault The vault making the call
     * @param _to The Ambient contract address
     * @param _data The call data containing userCmd
     * @return txType The type of transaction
     */
    function txGuard(address _vault, address _to, bytes memory _data)
        public override returns (uint16 txType)
    {
        bytes4 method = getMethod(_data);

        if (method == ICrocSwapDex.userCmd.selector) {
            (uint16 callpath, bytes memory cmd) = abi.decode(getParams(_data), (uint16, bytes));
            
            // Only support swap operations
            if (callpath != SWAP_PROXY_IDX) {
                revert UnsupportedCallpath(callpath);
            }
            
            _handleSwapCallpath(_vault, _to, cmd, 0);
            
            // Using enum for better code clarity
            txType = uint16(TransactionType.Exchange);
            
            // Return explicitly to ensure the value is passed back
            return uint16(TransactionType.Exchange);
        }

        // Default to Exchange for any other methods (can be refined later)
        txType = uint16(TransactionType.Exchange);
        return uint16(TransactionType.Exchange);
    }

    /**
     * @notice Validates userCmd calls with ETH value
     * @param _vault The vault making the call
     * @param _to The Ambient contract address
     * @param _data The call data containing userCmd
     * @param _nativeTokenAmount The ETH amount being sent
     * @return txType The type of transaction
     */
    function txGuard(address _vault, address _to, bytes memory _data, uint256 _nativeTokenAmount)
        public override returns (uint16 txType)
    {
        if (_nativeTokenAmount <= 0) revert PayableAmountMustBeGreaterThanZero();

        bytes4 method = getMethod(_data);

        if (method == ICrocSwapDex.userCmd.selector) {
            (uint16 callpath, bytes memory cmd) = abi.decode(getParams(_data), (uint16, bytes));
            
            // Only support swap operations
            if (callpath != SWAP_PROXY_IDX) {
                revert UnsupportedCallpath(callpath);
            }
            
            _handleSwapCallpath(_vault, _to, cmd, _nativeTokenAmount);
            
            // Using enum for better code clarity
            txType = uint16(TransactionType.Exchange);
            
            // Return explicitly to ensure the value is passed back
            return uint16(TransactionType.Exchange);
        }

        // Default to Exchange for any other methods (can be refined later)
        txType = uint16(TransactionType.Exchange);
        return uint16(TransactionType.Exchange);
    }

    /**
     * @notice Handles swap callpath validation and processing
     * @dev Parses Ambient swap command structure and validates tokens
     * @param _vault The vault making the call
     * @param _to The Ambient contract address
     * @param cmd The swap command data
     * @param _nativeTokenAmount The ETH amount being sent
     */
    function _handleSwapCallpath(
        address _vault, 
        address _to, 
        bytes memory cmd, 
        uint256 _nativeTokenAmount
    ) internal {
        // Extract token addresses and swap parameters from cmd data
        (
            address baseToken,
            address quoteToken,
            uint256 qty,
            bool isBuy
        ) = _parseSwapCommand(cmd);
        
        // Check if this is a Native Token swap
        bool isNativeSwap = _isNativeTokenId(baseToken) || _isNativeTokenAddress(quoteToken);
        
        if (isNativeSwap) {
            _handleNativeSwap(_vault, _to, cmd, _nativeTokenAmount);
            return;
        }
        
        // Standard ERC20 swap logic
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
        
        // Validate tokens are supported by vault
        IHasSupportedAsset supportedAsset = IHasSupportedAsset(_vault);
        
        // Check if source token is supported
        bool isSourceSupported = supportedAsset.isSupportedAsset(sourceToken);
        
        // Check if destination token is supported
        bool isDestSupported = supportedAsset.isSupportedAsset(destToken);
        
        // Skip validation for native token as source
        if (!isSourceSupported) {
            revert UnsupportedSourceAsset(sourceToken);
        }
        
        // Always validate destination token
        if (!isDestSupported) {
            revert UnsupportedDestinationAsset(destToken);
        }
        
        // Emit ExchangeFrom event for tracking
        emit ExchangeFrom(_vault, _to, sourceToken, qty, destToken);
    }
    
    /**
     * @notice Handles Native Token swap validation and processing
     * @param _vault The vault making the call
     * @param _to The Ambient contract address
     * @param cmd The swap command data
     * @param _nativeTokenAmount The ETH amount being sent
     */
    function _handleNativeSwap(
        address _vault,
        address _to,
        bytes memory cmd,
        uint256 _nativeTokenAmount
    ) internal {
        // Extract token info using low-level assembly to match CrocSwap format
        uint256 baseTokenId;
        uint256 quoteTokenId;
        address erc20Token;
        uint256 poolIdx;
        uint256 qty;
        bool isBuy;
        
        // Extract data using assembly for gas efficiency and to match CrocSwap's format
        assembly {
            // Extract special token IDs
            baseTokenId := mload(add(cmd, 32))   // Chunk 0: base token ID
            quoteTokenId := mload(add(cmd, 64))  // Chunk 1: quote token ID
            
            // Extract ERC20 token address (for Native token swaps, one token is always ERC20)
            erc20Token := mload(add(cmd, 96))    // Chunk 2: ERC20 token address
            
            // Extract pool index
            poolIdx := mload(add(cmd, 128))      // Chunk 3: poolIdx
            
            // Extract quantity from chunk 5 (bytes 160-192)
            qty := mload(add(cmd, 192))          // Chunk 5: quantity
            
            // Extract flags from chunk 7 (bytes 224-256)
            let flags := mload(add(cmd, 256))    // Chunk 7: flags
            isBuy := and(flags, 0x1)             // isBuy is the lowest bit
        }
        
        // Determine if Native token is being bought or sold
        bool isSellingNative = (baseTokenId == NATIVE_TOKEN_ID && !isBuy) || 
                               (quoteTokenId == 0 && isBuy);
        
        // Handle Native token validation
        if (isSellingNative) {
            // Selling Native token - validate that Native token is supported
            IHasSupportedAsset supportedAsset = IHasSupportedAsset(_vault);
            
            // For selling Native token, validate that:
            // 1. Native token (ETH) is supported
            // 2. The ERC20 token we're receiving is supported
            if (!supportedAsset.isSupportedAsset(NATIVE_TOKEN_ADDRESS)) {
                revert UnsupportedSourceAsset(NATIVE_TOKEN_ADDRESS);
            }
            
            if (!supportedAsset.isSupportedAsset(erc20Token)) {
                revert UnsupportedDestinationAsset(erc20Token);
            }
            
            // Check if enough Native token is being sent
            if (_nativeTokenAmount < qty) {
                revert InsufficientNativeTokenAmount(qty, _nativeTokenAmount);
            }
            
            // Emit ExchangeFrom event for tracking Native -> ERC20 swap
            emit ExchangeFrom(_vault, _to, NATIVE_TOKEN_ADDRESS, qty, erc20Token);
        } else {
            // Buying Native token - validate that ERC20 token is supported
            IHasSupportedAsset supportedAsset = IHasSupportedAsset(_vault);
            
            // For buying Native token, validate that:
            // 1. The ERC20 token we're spending is supported
            // 2. Native token (ETH) is supported
            if (!supportedAsset.isSupportedAsset(erc20Token)) {
                revert UnsupportedSourceAsset(erc20Token);
            }
            
            if (!supportedAsset.isSupportedAsset(NATIVE_TOKEN_ADDRESS)) {
                revert UnsupportedDestinationAsset(NATIVE_TOKEN_ADDRESS);
            }
            
            // Emit ExchangeFrom event for tracking ERC20 -> Native swap
            emit ExchangeFrom(_vault, _to, erc20Token, qty, NATIVE_TOKEN_ADDRESS);
        }
    }
    
    /**
     * @notice Parses Ambient swap command structure for ERC20 tokens
     * @dev Extracts token addresses, quantity and swap direction from binary data
     * @param cmd The swap command data
     * @return baseToken The base token address
     * @return quoteToken The quote token address
     * @return qty The swap quantity
     * @return isBuy Whether the operation is buying base token
     */
    function _parseSwapCommand(bytes memory cmd) 
        private 
        pure 
        returns (
            address baseToken,
            address quoteToken,
            uint256 qty,
            bool isBuy
        ) 
    {
        // Extract data using assembly for gas efficiency
        assembly {
            // Extract token addresses
            baseToken := mload(add(cmd, 32))   // Chunk 0: base token
            quoteToken := mload(add(cmd, 64))  // Chunk 1: quote token
            
            // Extract quantity from chunk 5 (bytes 160-192)
            qty := mload(add(cmd, 192))
            
            // Extract flags from chunk 7 (bytes 224-256)
            let flags := mload(add(cmd, 256))
            isBuy := and(flags, 0x1)
        }
        
        return (baseToken, quoteToken, qty, isBuy);
    }
    
    /**
     * @notice Checks if the address is actually a special Native Token ID
     * @param addr The address to check
     * @return True if the address is a Native Token ID
     */
    function _isNativeTokenId(address addr) private pure returns (bool) {
        // Check if address contains special Native Token ID value (0x2)
        return uint256(uint160(addr)) == NATIVE_TOKEN_ID;
    }
    
    /**
     * @notice Checks if the address is a Native Token address (address(0))
     * @param addr The address to check
     * @return True if the address is the Native Token address
     */
    function _isNativeTokenAddress(address addr) private pure returns (bool) {
        return addr == NATIVE_TOKEN_ADDRESS;
    }
} 