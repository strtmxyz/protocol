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
                governanceAddress: '0x4Ab20278544788aF9f7777FcC43b4213F3624e24', // Fresh deployment
                assetHandlerAddress: '0xea19c9fF106d1576B27b28DA1650A61E47D843E4', // Fresh deployment
                vaultFactoryAddress: '0x14582A63e5f5ADE7a4FB8E21959b1023F1A9f92A',
                vaultImplementationAddress: '0x4065098183616C132A9d100a31dCCbE98f9DB13B', // Deployed implementation
            }
        case "sonicBlazeTestnet":
            return {
                USDC: '0x0000000000000000000000000000000000000000', // Sonic testnet USDC
                wETH: '0x0000000000000000000000000000000000000000', // Sonic testnet WETH
                ETH: '0x0000000000000000000000000000000000000000',
                governanceAddress: '0x0000000000000000000000000000000000000000', // TODO: Deploy
                assetHandlerAddress: '0x0000000000000000000000000000000000000000', // TODO: Deploy
                vaultFactoryAddress: '0x0000000000000000000000000000000000000000', // TODO: Deploy
            }
        case "sonicMainnet":
            return {
                USDC: '0x0000000000000000000000000000000000000000', // Sonic mainnet USDC
                wETH: '0x0000000000000000000000000000000000000000', // Sonic mainnet WETH  
                ETH: '0x0000000000000000000000000000000000000000',
                governanceAddress: '0x0000000000000000000000000000000000000000', // TODO: Deploy
                assetHandlerAddress: '0x0000000000000000000000000000000000000000', // TODO: Deploy
                vaultFactoryAddress: '0x0000000000000000000000000000000000000000', // TODO: Deploy
            }
        default:
            throw new Error(`Unsupported network: ${networkName}`)
    }
}