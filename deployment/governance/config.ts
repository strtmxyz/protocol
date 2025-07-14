import { ERC20AssetType, NativeTokenType, LiquidityAssetType } from "../config/tokens"

export interface GovernanceConfig {
    assetGuards: {
        assetType: number,
        guardAddress: string
    }[],
    contractGuards: {
        externalAddress: string,
        guardAddress: string
    }[]
}

// https://docs.berachain.com/developers/deployed-contracts
export const getGovernanceConfig = (networkName: string): GovernanceConfig => {
    switch(networkName) {
        case "localhost":
        case "hardhat":
            return {
                assetGuards: [
                    {
                        assetType: ERC20AssetType,
                        guardAddress: '0x0000000000000000000000000000000000000000' // Will be set after deployment
                    },
                    {
                        assetType: NativeTokenType,
                        guardAddress: '0x0000000000000000000000000000000000000000' // Will be set after deployment
                    },
                ],
                contractGuards: [],
            }
        case "monadTestnet":
            return {
                assetGuards: [
                    {
                        assetType: ERC20AssetType,
                        guardAddress: '0x505668d7cAEadF0EE969CF3117edC7d5360d0e75'
                    },
                    {
                        assetType: NativeTokenType,
                        guardAddress: '0x38b27Ad8a21e33fc93f4c37129CD8fc805b245F9'
                    },

                ],
                contractGuards: [
                    {
                        externalAddress: '0x88B96aF200c8a9c35442C8AC6cd3D22695AaE4F0',
                        guardAddress: '0x4A70CbCe9c5c4d6E7c9236aa004F6ba23a805584' //AmbientGuard
                    },
                ],
            }
        case "sonicBlazeTestnet":
            return {
                assetGuards: [
                    {
                        assetType: ERC20AssetType,
                        guardAddress: '0x0000000000000000000000000000000000000000' // TODO: Deploy ERC20Guard
                    },
                    {
                        assetType: NativeTokenType,
                        guardAddress: '0x0000000000000000000000000000000000000000' // TODO: Deploy ETHGuard
                    },
                ],
                contractGuards: [],
            }
        case "sonicMainnet":
            return {
                assetGuards: [
                    {
                        assetType: ERC20AssetType,
                        guardAddress: '0x0000000000000000000000000000000000000000' // TODO: Deploy ERC20Guard
                    },
                    {
                        assetType: NativeTokenType,
                        guardAddress: '0x0000000000000000000000000000000000000000' // TODO: Deploy ETHGuard
                    },
                ],
                contractGuards: [],
            }
        default:
            throw new Error(`Unsupported network: ${networkName}`)
    }
}