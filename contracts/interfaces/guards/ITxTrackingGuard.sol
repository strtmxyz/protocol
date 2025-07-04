// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITxTrackingGuard {
  
  /// @notice Check if tx tracking guard is enabled
  /// @return True if tx tracking guard is enabled, false otherwise 
  function isTxTrackingGuard() external view returns (bool);

  /// @notice After tx guard
  /// @param vault Vault address
  /// @param to Target address
  /// @param data Call data
  /// @param returnedData Returned data 
  function afterTxGuard(
    address vault,
    address to,
    bytes calldata data,
    bytes calldata returnedData
  ) external;
}
