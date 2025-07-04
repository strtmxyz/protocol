import { ERC20AssetType, NativeTokenType, LiquidityAssetType, VertexProtocolAssetType} from "../config/tokens"

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
        case "arbitrumSepolia":
            return {
                assetGuards: [
                    {
                        assetType: ERC20AssetType,
                        guardAddress: '0xfEEcCfb90EBc7a2dab4aE30790a880D4EAD08A81'
                    },
                    {
                        assetType: NativeTokenType,
                        guardAddress: '0xb13A03a30fbC567BA2959D7ef60447e0DAb07C9A'
                    },
                    {
                        assetType: VertexProtocolAssetType,
                        guardAddress: '0xE22DE744aB5428AAef72BC6448D6f27341BBb1D1'
                    }
                ],
                contractGuards: [
                    // VertexProtocol
                    {
                        externalAddress: '0xaDeFDE1A14B6ba4DA3e82414209408a49930E8DC',
                        guardAddress: '0xE800a81cacdFF3FA0Bc0cf3Ff0433c0C8b9699dc'
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