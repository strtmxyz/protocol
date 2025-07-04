// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @title IGuard
/// @notice Interface for IGuard contract
interface IGuard {
  /// @notice Guard transaction
  /// @param vault Pot address
  /// @param to Target address
  /// @param data Call data
  /// @return txType Transaction type
  function txGuard(
    address vault,
    address to,
    bytes calldata data
  ) external returns (uint16 txType); // TODO: eventually update `txType` to be of enum type as per ITransactionTypes

  /// @notice Guard transaction
  /// @param vault Pot address
  /// @param to Target address
  /// @param data Call data
  /// @param nativeAmount Native amount
  /// @return txType Transaction type
  function txGuard(
    address vault,
    address to,
    bytes calldata data,
    uint256 nativeAmount
  ) external returns (uint16 txType); // TODO: eventually update `txType` to be of enum type as per ITransactionTypes
}