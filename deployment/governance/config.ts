import { ERC20AssetType, NativeTokenType, LiquidityAssetType, PancakeLPAssetType} from "../config/tokens"

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
                        guardAddress: ''
                    },
                    {
                        assetType: NativeTokenType,
                        guardAddress: ''
                    },
                    {
                        assetType: PancakeLPAssetType,
                        guardAddress: ''
                    }
                ],
                contractGuards: [
                    {
                        externalAddress: '',
                        guardAddress: ''
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