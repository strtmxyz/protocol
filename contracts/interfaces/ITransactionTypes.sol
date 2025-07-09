//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Transaction type events used in pool execTransaction() contract guards
/// @dev Gradually migrate to these events as we update / add new contract guards
interface ITransactionTypes {
  // Enum representing Transaction Types
  enum TransactionType {
    NotUsed, // 0
    Approve, // 1
    Exchange, // 2
    AddLiquidity, // 3
    RemoveLiquidity, // 4
    SetDelegateApproval, // 5
    Stake, // 6
    Unstake, // 7
    Claim, // 8
    WrapNativeToken, // 9
    UnwrapNativeToken, // 10
  }
}