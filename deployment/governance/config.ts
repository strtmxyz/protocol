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
                        guardAddress: '0xaEE58BDC21EbA74D79515301937b16d4B7f814A2'
                    },
                    {
                        assetType: NativeTokenType,
                        guardAddress: '0x38d79DD9D4F11d98e855Bd68bd2dE404e7B4778f'
                    },
                    {
                        assetType: PancakeLPAssetType,
                        guardAddress: '0x052D9cE31bb075dc5A267698196EC0AcE558a520'
                    }
                ],
                contractGuards: [
                    {
                        externalAddress: '0x3a3eBAe0Eec80852FBC7B9E824C6756969cc8dc1',
                        guardAddress: '0x45b4F4Ba9942d705275D4a5D2Eb4577b4D78A94a' //PancakeV2RouterGuard
                    },
                    {
                        externalAddress: '0x94D220C58A23AE0c2eE29344b00A30D1c2d9F1bc',
                        guardAddress: '0xBA83A1434aA57cC24ffEd092b29367B7984f9cac' //PancakeV3RouterGuard
                    },
                    {
                        externalAddress: '0x88B96aF200c8a9c35442C8AC6cd3D22695AaE4F0',
                        guardAddress: '0x300710EEAF921567AD3Ed7f94b3EE54c7b8D5632' //AmbientGuard
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