// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../../interfaces/guards/IPlatformGuard.sol";
import "../../utils/TxDataUtils.sol";
import "../../interfaces/IHasSupportedAsset.sol";
import "../../interfaces/IVault.sol";
import "../../interfaces/ITransactionTypes.sol";
import "../../interfaces/external/kyberswap/IMetaAggregationRouterV2.sol";
import "@uniswap/v3-periphery/contracts/libraries/Path.sol";
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

contract KyberswapGuard is TxDataUtils, IPlatformGuard, ITransactionTypes, Initializable {
  using Path for bytes;

  string public override platformName;
  function initialize() public initializer {
    platformName = "KyberswapGuard";
  }

  function txGuard(address _vault, address _to, bytes memory _data)
    public override returns (uint16 txType)
  {
    bytes4 method = getMethod(_data);

    if (method == IMetaAggregationRouterV2.swap.selector) {
      (IMetaAggregationRouterV2.SwapExecutionParams memory swapExecutionParams) = abi.decode(getParams(_data), (IMetaAggregationRouterV2.SwapExecutionParams));
      address srcAsset = swapExecutionParams.desc.srcToken;
      address dstAsset = swapExecutionParams.desc.dstToken;

      IHasSupportedAsset supportedAsset = IHasSupportedAsset(_vault);
      if (!supportedAsset.isSupportedAsset(dstAsset)) revert UnsupportedDestinationAsset();

      if (_vault != swapExecutionParams.desc.dstReceiver) revert RecipientIsNotVault();

      emit ExchangeFrom(_vault, _to, srcAsset, swapExecutionParams.desc.amount, dstAsset);

      txType = uint16(TransactionType.Exchange);
    }
    else if (method == IMetaAggregationRouterV2.swapSimpleMode.selector) {
      (,IMetaAggregationRouterV2.SwapDescriptionV2 memory swapDescriptionV2) = abi.decode(getParams(_data), (address,IMetaAggregationRouterV2.SwapDescriptionV2));
      address srcAsset = swapDescriptionV2.srcToken;
      address dstAsset = swapDescriptionV2.dstToken;

      IHasSupportedAsset supportedAsset = IHasSupportedAsset(_vault);
      if (!supportedAsset.isSupportedAsset(dstAsset)) revert UnsupportedDestinationAsset();

      if (_vault != swapDescriptionV2.dstReceiver) revert RecipientIsNotVault();

      emit ExchangeFrom(_vault, _to, srcAsset, swapDescriptionV2.amount, dstAsset);

      txType = uint16(TransactionType.Exchange);
    }

    return txType;
  }

  function txGuard(address _vault, address _to, bytes memory _data, uint256 _nativeTokenAmount)
    public override returns (uint16 txType)
  {
    if (_nativeTokenAmount <= 0) revert PayableAmountMustBeGreaterThanZero();

    IHasSupportedAsset supportedAsset = IHasSupportedAsset(_vault);
    if (!supportedAsset.isSupportedAsset(address(0))) revert UnsupportedSourceAsset();

    bytes4 method = getMethod(_data);

    if (method == IMetaAggregationRouterV2.swap.selector) {
      (IMetaAggregationRouterV2.SwapExecutionParams memory swapExecutionParams) = abi.decode(getParams(_data), (IMetaAggregationRouterV2.SwapExecutionParams));
      address dstAsset = swapExecutionParams.desc.dstToken;

      if (!supportedAsset.isSupportedAsset(dstAsset)) revert UnsupportedDestinationAsset();

      if (_vault != swapExecutionParams.desc.dstReceiver) revert RecipientIsNotVault();

      emit ExchangeFrom(_vault, _to, address(0), swapExecutionParams.desc.amount, dstAsset);

      txType = uint16(TransactionType.Exchange);
    }
    else if (method == IMetaAggregationRouterV2.swapSimpleMode.selector) {
      (,IMetaAggregationRouterV2.SwapDescriptionV2 memory swapDescriptionV2) = abi.decode(getParams(_data), (address,IMetaAggregationRouterV2.SwapDescriptionV2));
      address dstAsset = swapDescriptionV2.dstToken;

      if (!supportedAsset.isSupportedAsset(dstAsset)) revert UnsupportedDestinationAsset();

      if (_vault != swapDescriptionV2.dstReceiver) revert RecipientIsNotVault();

      emit ExchangeFrom(_vault, _to, address(0), swapDescriptionV2.amount, dstAsset);

      txType = uint16(TransactionType.Exchange);
    }

    return txType;
  }
}