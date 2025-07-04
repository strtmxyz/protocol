// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface Clearinghouse {
    function getHealth(bytes32 subaccount, uint8 healthType) external view returns(int128);
}