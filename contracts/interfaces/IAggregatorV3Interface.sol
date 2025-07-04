// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @title IAggregatorV3Interface
/// @notice Interface for IAggregatorV3Interface contract
interface IAggregatorV3Interface {
   function decimals() external view returns (uint8);

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}