import { getCommonConfig } from "./common";

export const ERC20AssetType = 1
export const NativeTokenType = 2
export const LiquidityAssetType = 3
export const VertexProtocolAssetType = 4
// https://docs.berachain.com/developers/deployed-contracts
export const getSupportedTokens = (networkName: string): {
    address: string,
    aggregator: string,
    type: number,
    isUnderlying: boolean,
}[] => {
    const config = getCommonConfig(networkName);

    switch(networkName) {
        case "arbitrumSepolia":
            return [
                {
                    // ETH
                    address: config.ETH,
                    aggregator: '0xd30e2101a97dcbAeBCBC04F14C3f624E67A35165', // ETH/USD on Arbitrum Sepolia
                    type: NativeTokenType, // Native Token
                    isUnderlying: false // Native ETH cannot be underlying asset
                },
                {
                    // WETH
                    address: config.wETH,
                    aggregator: '0xd30e2101a97dcbAeBCBC04F14C3f624E67A35165', // ETH/USD on Arbitrum Sepolia
                    type: ERC20AssetType, // ERC20
                    isUnderlying: true // Can be used as vault underlying
                },
                {
                    // USDC
                    address: '0xd32ea1c76ef1c296f131dd4c5b2a0aac3b22485a',
                    aggregator: '0x0153002d20B96532C639313c2d54c3dA09109309', // USDC/USD on Arbitrum Sepolia
                    type: ERC20AssetType, // ERC20
                    isUnderlying: true // Can be used as vault underlying
                },
                {
                    // Vertex Protocol
                    address: '0xDFA3926296eaAc8E33c9798836Eae7e8CA1B02FB',
                    aggregator: '', // Custom oracle needed for Vertex assets
                    type: VertexProtocolAssetType, // VertexProtocolAsset
                    isUnderlying: false // Vertex assets cannot be underlying
                },
            ]
        case "sonicBlazeTestnet":
            return [
                {
                    // W
                    address: config.ETH,
                    aggregator: '',
                    type: NativeTokenType, // Native Token
                    isUnderlying: false
                },
                {
                    // sW
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
                },
                {
                    // Vertex Protocol
                    address: '',
                    aggregator:'',
                    type: VertexProtocolAssetType, // VertexProtocolAsset
                    isUnderlying: false
                },
            ]
        case "sonicMainnet":
            return [
                {
                    // W
                    address: config.ETH,
                    aggregator: '',
                    type: NativeTokenType, // Native Token
                    isUnderlying: false
                },
                {
                    // sW
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
                },
                {
                    // Vertex Protocol
                    address: '',
                    aggregator:'',
                    type: VertexProtocolAssetType, // VertexProtocolAsset
                    isUnderlying: false
                },
        ]
        default:
            throw new Error(`Unsupported network: ${networkName}`)
    }
}