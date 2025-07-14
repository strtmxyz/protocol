// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

struct CurveMath {
    uint128 priceRoot_;
    uint128 ambientSeeds_;
    uint128 concLiq_;
    uint64 seedDeflator_;
    uint64 concGrowth_;
}

interface ICrocQuery {
    function queryPrice(address base, address quote, uint256 poolIdx) external view returns (uint128);
    
    function queryCurve(address base, address quote, uint256 poolIdx) external view returns (CurveMath memory);
    
    function queryCurveTick(address base, address quote, uint256 poolIdx) external view returns (int24);
    
    function queryRangeTokens(address owner, address base, address quote, uint256 poolIdx, int24 bidTick, int24 askTick) 
        external view returns (uint128 liq, uint128 baseQty, uint128 quoteQty);
    
    function queryRangePosition(address owner, address base, address quote, uint256 poolIdx, int24 bidTick, int24 askTick) 
        external view returns (uint128 liq, uint256 timestamp);
}