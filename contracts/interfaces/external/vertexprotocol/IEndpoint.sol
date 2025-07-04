// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IEndpoint {
    function depositCollateral(bytes12 subaccountName, uint32 productId, uint128 amount) external;
    function depositCollateralWithReferral(bytes12 subaccountName, uint32 productId, uint128 amount, string calldata referralCode) external;
    function submitSlowModeTransaction(bytes calldata transaction) external;
} 