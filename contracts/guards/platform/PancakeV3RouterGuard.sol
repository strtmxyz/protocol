// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../interfaces/guards/IPlatformGuard.sol";
import "../../utils/TxDataUtils.sol";
import "../../interfaces/IHasSupportedAsset.sol";
import "../../interfaces/ITransactionTypes.sol";
import "../../interfaces/external/pancakeswap/IUniversalRouter.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/*//////////////////////////////////////////////////////////////
                            CUSTOM ERRORS
//////////////////////////////////////////////////////////////*/

error UnsupportedSourceAsset();
error ExpiredDeadline();
error PayableAmountMustBeGreaterThanZero();

contract PancakeV3RouterGuard is TxDataUtils, IPlatformGuard, ITransactionTypes, Initializable {
    string public override platformName;
    
    function initialize() public initializer {
        platformName = "PancakeV3RouterGuard";
    }

    function txGuard(address _vault, address _to, bytes memory _data)
        public override returns (uint16 txType)
    {
        bytes4 method = getMethod(_data);
        
        if (method == IUniversalRouter.execute.selector) {
            (, , uint256 deadline) = abi.decode(getParams(_data), (bytes, bytes[], uint256));
            _validateDeadline(deadline);
            
            emit ExchangeFrom(_vault, _to, address(0), 0, address(0));
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
        
        if (method == IUniversalRouter.execute.selector) {
            (, , uint256 deadline) = abi.decode(getParams(_data), (bytes, bytes[], uint256));
            _validateDeadline(deadline);
            
            emit ExchangeFrom(_vault, _to, address(0), _nativeTokenAmount, address(0));
            txType = uint16(TransactionType.Exchange);
        }
        
        return txType;
    }
    
    /*//////////////////////////////////////////////////////////////
                            VALIDATION HELPERS
    //////////////////////////////////////////////////////////////*/
    
    function _validateDeadline(uint256 _deadline) internal view {
        if (_deadline < block.timestamp) revert ExpiredDeadline();
    }
} 