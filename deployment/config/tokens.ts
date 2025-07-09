import { getCommonConfig } from "./common";

export const ERC20AssetType = 1
export const NativeTokenType = 2
export const LiquidityAssetType = 3
export const BeanAssetType = 4
export const PancakeLPAssetType = 5
// https://docs.berachain.com/developers/deployed-contracts
export const getSupportedTokens = (networkName: string): {
    address: string,
    aggregator: string,
    type: number,
    isUnderlying: boolean,
}[] => {
    const config = getCommonConfig(networkName);

    switch(networkName) {
        case "monadTestnet":
            return [
                {
                    // ETH
                    address: config.ETH,
                    aggregator: '0x55dCA5CBe2042918D18b8946cA367cffC6798aE3', // ETH/USD on Monad Testnet
                    type: NativeTokenType, // Native Token
                    isUnderlying: false // Native ETH cannot be underlying asset
                },
                {
                    // wETH
                    address: config.wETH,
                    aggregator: '0x55dCA5CBe2042918D18b8946cA367cffC6798aE3', // ETH/USD on Monad Testnet
                    type: ERC20AssetType, // ERC20
                    isUnderlying: true // Can be used as vault underlying
                },
                {
                    // USDC
                    address: '0xd32ea1c76ef1c296f131dd4c5b2a0aac3b22485a',
                    aggregator: '0x74265c4060CB011CE32fabB2682A08B3390C061D', // USDC/USD on Monad Testnet
                    type: ERC20AssetType, // ERC20
                    isUnderlying: true // Can be used as vault underlying
                },
                {
                    // USDT
                    address: '0x88b8E2161DEDC77EF4ab7585569D2415a1C1055D',
                    aggregator: '0xc9Ba9f4EFdbaA1158DE97658e428D1962dB60616', // USDT/USD on Monad Testnet
                    type: ERC20AssetType, // ERC20
                    isUnderlying: true // Can be used as vault underlying
                },
                {
                    // ETH
                    address: '0x836047a99e11F376522B447bffb6e3495Dd0637c',
                    aggregator: '0x0c76859E85727683Eeba0C70Bc2e0F5781337818', // ETH/USD on Monad Testnet
                    type: ERC20AssetType, // ERC20
                    isUnderlying: true // Can be used as vault underlying
                }
            ]
        case "sonicBlazeTestnet":
            return [
                {
                    // ETH
                    address: config.ETH,
                    aggregator: '',
                    type: NativeTokenType, // Native Token
                    isUnderlying: false
                },
                {
                    // wETH
                    address: config.wETH,
                    aggregator: '',
                    type: ERC20AssetType, // ERC20
                    isUnderlying: true
                },
                {
                    // USDC
                    address: '',
                    aggregator: '',
                    type: ERC20AssetType, // ERC20
                    isUnderlying: true
                },
                {
                    // WETH
                    address: '',
                    aggregator:'',
                    type: ERC20AssetType, // ERC20
                    isUnderlying: true
                }
            ]
        case "sonicMainnet":
            return [
                {
                    // ETH
                    address: config.ETH,
                    aggregator: '',
                    type: NativeTokenType, // Native Token
                    isUnderlying: false
                },
                {
                    // wETH
                    address: config.wETH,
                    aggregator: '',
                    type: ERC20AssetType, // ERC20
                    isUnderlying: true
                },
                {
                    // USDC
                    address: '',
                    aggregator: '',
                    type: ERC20AssetType, // ERC20
                    isUnderlying: true
                },
                {
                    // WETH
                    address: '',
                    aggregator:'',
                    type: ERC20AssetType, // ERC20
                    isUnderlying: true
                }
        ]
        default:
            throw new Error(`Unsupported network: ${networkName}`)
    }
}