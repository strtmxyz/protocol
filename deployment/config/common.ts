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
                governanceAddress: '0x8288b14B50860Db010a5a0fC5F467b2130C1dD75', // Fresh deployment
                assetHandlerAddress: '0xea19c9fF106d1576B27b28DA1650A61E47D843E4', // Fresh deployment
                vaultFactoryAddress: '0x1Bd510B984Cd4dD959e9Bad153f6C1EA87af69Dd',
                vaultImplementationAddress: '0x1403Fa307994c6015BB0F88E0679Cd4277543470', // Deployed implementation
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