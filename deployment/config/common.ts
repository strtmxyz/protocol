export interface CommonConfig {
    USDC: string;
    wETH: string;
    ETH: string;
    governanceAddress: string;
    assetHandlerAddress: string;
    vaultFactoryAddress: string;
    vaultImplementationAddress?: string;
}

// https://docs.berachain.com/developers/deployed-contracts
export const getCommonConfig = (networkName: string): CommonConfig => {
    switch(networkName) {
        case "localhost":
        case "hardhat":
            return {
                USDC: '0xA0b86a33E6441b8EBBCBaBA6FD59A54eBBEbA2dD', // Mock USDC on localhost
                wETH: '0x8A791620dd6260079BF849Dc5567aDC3F2FdC318', // Mock WETH on localhost
                ETH: '0x0000000000000000000000000000000000000000',
                governanceAddress: '0x0000000000000000000000000000000000000000', // Will be set after deployment
                assetHandlerAddress: '0x0000000000000000000000000000000000000000', // Will be set after deployment
                vaultFactoryAddress: '0x0000000000000000000000000000000000000000', // Will be set after deployment
            }
        case "arbitrumSepolia":
            return {
                USDC: '0xd32ea1c76ef1c296f131dd4c5b2a0aac3b22485a', // vertex usdc
                wETH: '0x94B3173E0a23C28b2BA9a52464AC24c2B032791c', // vertex MockwETH
                ETH: '0x0000000000000000000000000000000000000000',
                governanceAddress: '0xdCeD2CBC87A0d99e8F757182eb3a628F1e78B89B', // Fresh deployment
                assetHandlerAddress: '0x5cd2C89a4ea3BbeC79F027e53CAB88Fb21680210', // Fresh deployment
                vaultFactoryAddress: '0x65fA89C281F0762971bEb4F7031c07DBe04F7089',
                vaultImplementationAddress: '0x0c942878e5EEb812Ebb77F257476E7C92B6909e2', // Deployed implementation
            }
        case "sonicBlazeTestnet":
            return {
                USDC: '0x29219dd400f2Bf60E5a23d13Be72B486D4038894', // Sonic testnet USDC
                wETH: '0x039e2fB66102314Ce7b64Ce5Ce3E5183bc94aD38', // Sonic testnet WETH
                ETH: '0x0000000000000000000000000000000000000000',
                governanceAddress: '0x0000000000000000000000000000000000000000', // TODO: Deploy
                assetHandlerAddress: '0x0000000000000000000000000000000000000000', // TODO: Deploy
                vaultFactoryAddress: '0x0000000000000000000000000000000000000000', // TODO: Deploy
            }
        case "sonicMainnet":
            return {
                USDC: '0x29219dd400f2Bf60E5a23d13Be72B486D4038894', // Sonic mainnet USDC
                wETH: '0x039e2fB66102314Ce7b64Ce5Ce3E5183bc94aD38', // Sonic mainnet WETH  
                ETH: '0x0000000000000000000000000000000000000000',
                governanceAddress: '0x0000000000000000000000000000000000000000', // TODO: Deploy
                assetHandlerAddress: '0x0000000000000000000000000000000000000000', // TODO: Deploy
                vaultFactoryAddress: '0x0000000000000000000000000000000000000000', // TODO: Deploy
            }
        default:
            throw new Error(`Unsupported network: ${networkName}`)
    }
}