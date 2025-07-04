// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @title IHasDaoInfo
/// @notice Interface for IHasDaoInfo contract
interface IHasDaoInfo {
  function getDaoFee() external view returns (uint256, uint256);

  function daoAddress() external view returns (address);
}