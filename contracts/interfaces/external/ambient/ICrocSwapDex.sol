// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ICrocSwapDex {
  function userCmd(uint16 callpath, bytes calldata cmd) external payable returns (bytes memory);
}
