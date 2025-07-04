// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IMetaAggregationRouterV2 {
  struct SwapDescriptionV2 {
    address srcToken;
    address dstToken;
    address[] srcReceivers; // transfer src token to these addresses, default
    uint256[] srcAmounts;
    address[] feeReceivers;
    uint256[] feeAmounts;
    address dstReceiver;
    uint256 amount;
    uint256 minReturnAmount;
    uint256 flags;
    bytes permit;
  }

  struct SwapExecutionParams {
    address callTarget; // call this address
    address approveTarget; // approve this address if _APPROVE_FUND set
    bytes targetData;
    SwapDescriptionV2 desc;
    bytes clientData;
  }

  function swap(SwapExecutionParams calldata execution)
    external
    returns (uint256 returnAmount, uint256 gasUsed);

  function swapSimpleMode(
    address caller,
    SwapDescriptionV2 memory desc,
    bytes calldata executorData,
    bytes calldata clientData
  ) external returns (uint256 returnAmount, uint256 gasUsed);
}
