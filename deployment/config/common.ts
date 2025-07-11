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
        case "monadTestnet":
            return {
                USDC: '0xf817257fed379853cDe0fa4F97AB987181B1E5Ea', // usdc
                wETH: '0x760AfE86e5de5fa0Ee542fc7B7B713e1c5425701', // wMON
                ETH: '0x0000000000000000000000000000000000000000',
                governanceAddress: '0xA77449604aF0b34d93C834dA7c2A95b21BDB5fbC', // Fresh deployment
                assetHandlerAddress: '0x91280743D277472bf3AE09254D13d4a72cA2cA98', // Fresh deployment
                vaultFactoryAddress: '0x187eBab83F01BC32975a051adb69171b23dEEeca',
                vaultImplementationAddress: '0xb2c41d947179eed98a1d05adecd3c9fb933cf4c3', // Deployed implementation
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