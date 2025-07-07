// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPancakeV2Pair {
    
  function token0() external view returns (address);

  function token1() external view returns (address);

  function totalSupply() external view returns (uint256);

  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

  function price0CumulativeLast() external view returns (uint256);

  function price1CumulativeLast() external view returns (uint256);

  function burn(address to) external returns (uint256 amount0, uint256 amount1);
}