import { expect } from "chai";
import { ethers } from "hardhat";
import { Signer } from "ethers";

describe("⚡ Gas Optimizations Tests", function () {
    let vault: any;
    let vaultFactory: any;
    let usdc: any;
    let deployer: Signer;
    let manager: Signer;
    let user1: Signer;
    let vaultAddress: string;

    beforeEach(async function () {
        [deployer, manager, user1] = await ethers.getSigners();

        // Deploy system components following working pattern
        const AssetHandler = await ethers.getContractFactory("AssetHandler");
        const assetHandler = await AssetHandler.deploy();
        await assetHandler.waitForDeployment();
        await assetHandler.initialize([]);

        const Governance = await ethers.getContractFactory("Governance");
        const governance = await Governance.deploy();
        await governance.waitForDeployment();
        await governance.initialize();

        const Vault = await ethers.getContractFactory("Vault");
        const vaultImplementation = await Vault.deploy();
        await vaultImplementation.waitForDeployment();

        const VaultFactory = await ethers.getContractFactory("VaultFactory");
        vaultFactory = await VaultFactory.deploy();
        await vaultFactory.waitForDeployment();
        await vaultFactory.initialize(
            await assetHandler.getAddress(),
            await deployer.getAddress(),
            await governance.getAddress()
        );
        await vaultFactory.updateVaultImplementation(await vaultImplementation.getAddress());

        await vaultFactory.setFactorySettings(
            ethers.parseUnits("100000", 6),
            ethers.parseUnits("100", 6),
            ethers.parseEther("0.01")
        );

        // Create mock USDC
        const MockERC20 = await ethers.getContractFactory("MockERC20");
        usdc = await MockERC20.deploy("USD Coin", "USDC", 6);
        await usdc.waitForDeployment();

        // Mint tokens and whitelist
        await usdc.mint(await user1.getAddress(), ethers.parseUnits("10000", 6));
        await vaultFactory.addUnderlyingAssetWhitelist(await usdc.getAddress());
        await vaultFactory.setAssetWhitelist(await usdc.getAddress(), 1, true);
    });

    describe("🎯 Fee Parameter Gas Optimizations", function () {
        it("Should handle maximum uint16 fee values (65535)", async function () {
            const maxUint16 = 65535;

            const tx = await vaultFactory.createVault(
                "Max Fee Vault",
                "MFV",
                await usdc.getAddress(),
                await manager.getAddress(),
                ethers.parseUnits("50000", 6),
                maxUint16,
                maxUint16,
                { value: ethers.parseEther("0.01") }
            );

            const receipt = await tx.wait();
            const vaultCreatedEvent = receipt?.logs.find((log: any) => {
                try {
                    const parsedLog = vaultFactory.interface.parseLog(log);
                    return parsedLog?.name === "VaultCreated";
                } catch {
                    return false;
                }
            });

            expect(vaultCreatedEvent).to.not.be.undefined;
            vaultAddress = vaultFactory.interface.parseLog(vaultCreatedEvent!).args.vault;
            vault = await ethers.getContractAt("Vault", vaultAddress);

            const managementFee = await vault.managementFee();
            const performanceFee = await vault.performanceFee();

            expect(managementFee).to.equal(maxUint16);
            expect(performanceFee).to.equal(maxUint16);
        });

        it("Should reject fee values exceeding uint16 max in updateVaultFees", async function () {
            // Create a vault first
            const tx = await vaultFactory.createVault(
                "Test Vault", "TV", await usdc.getAddress(), 
                await manager.getAddress(), ethers.parseUnits("50000", 6),
                200, 1000, { value: ethers.parseEther("0.01") }
            );

            const receipt = await tx.wait();
            const vaultCreatedEvent = receipt?.logs.find((log: any) => {
                try {
                    const parsedLog = vaultFactory.interface.parseLog(log);
                    return parsedLog?.name === "VaultCreated";
                } catch {
                    return false;
                }
            });

            vaultAddress = vaultFactory.interface.parseLog(vaultCreatedEvent!).args.vault;
            const exceedsUint16 = 65536;

            await expect(
                vaultFactory.updateVaultFees(vaultAddress, exceedsUint16, 1000, 50, 1000)
            ).to.be.revertedWithCustomError(vaultFactory, "ManagementFeeExceedsMax");
        });

        it("Should handle zero fee values correctly", async function () {
            const tx = await vaultFactory.createVault(
                "Zero Fee Vault", "ZFV", await usdc.getAddress(),
                await manager.getAddress(), ethers.parseUnits("50000", 6),
                0, 0, { value: ethers.parseEther("0.01") }
            );

            const receipt = await tx.wait();
            const vaultCreatedEvent = receipt?.logs.find((log: any) => {
                try {
                    const parsedLog = vaultFactory.interface.parseLog(log);
                    return parsedLog?.name === "VaultCreated";
                } catch {
                    return false;
                }
            });

            vaultAddress = vaultFactory.interface.parseLog(vaultCreatedEvent!).args.vault;
            vault = await ethers.getContractAt("Vault", vaultAddress);

            const managementFee = await vault.managementFee();
            const performanceFee = await vault.performanceFee();

            expect(managementFee).to.equal(0);
            expect(performanceFee).to.equal(0);
        });
    });

    describe("🔍 Query Optimization Tests", function () {
        beforeEach(async function () {
            // Create multiple vaults for testing O(n) vs O(2n) optimization
            for (let i = 0; i < 3; i++) {
                const tx = await vaultFactory.createVault(
                    `Test Vault ${i}`, `TV${i}`, await usdc.getAddress(),
                    await manager.getAddress(), ethers.parseUnits("50000", 6),
                    200 + i * 50, 1000 + i * 100,
                    { value: ethers.parseEther("0.01") }
                );
                await tx.wait();
            }
        });

        it("Should efficiently query vaults by manager (O(n) optimization)", async function () {
            const managerVaults = await vaultFactory.getVaultsByManager(await manager.getAddress());
            expect(managerVaults.length).to.equal(3);

            // Verify all returned vaults belong to the manager
            for (const vaultAddr of managerVaults) {
                const vaultManager = await vaultFactory.getVaultManager(vaultAddr);
                expect(vaultManager).to.equal(await manager.getAddress());
            }
        });

        it("Should handle empty results efficiently", async function () {
            const noVaults = await vaultFactory.getVaultsByManager(await user1.getAddress());
            expect(noVaults.length).to.equal(0);
        });
    });

    describe("⚙️ Storage Packing Validation", function () {
        it("Should validate fee storage packing is working", async function () {
            const tx = await vaultFactory.createVault(
                "Storage Test Vault", "STV", await usdc.getAddress(),
                await manager.getAddress(), ethers.parseUnits("50000", 6),
                12345, 54321, { value: ethers.parseEther("0.01") }
            );

            const receipt = await tx.wait();
            const vaultCreatedEvent = receipt?.logs.find((log: any) => {
                try {
                    const parsedLog = vaultFactory.interface.parseLog(log);
                    return parsedLog?.name === "VaultCreated";
                } catch {
                    return false;
                }
            });

            vaultAddress = vaultFactory.interface.parseLog(vaultCreatedEvent!).args.vault;
            vault = await ethers.getContractAt("Vault", vaultAddress);

            const managementFee = await vault.managementFee();
            const performanceFee = await vault.performanceFee();
            const withdrawalFee = await vault.withdrawalFee();
            const protocolFee = await vault.protocolFee();

            expect(managementFee).to.equal(12345);
            expect(performanceFee).to.equal(54321);
            expect(withdrawalFee).to.equal(50);  // Default 0.5%
            expect(protocolFee).to.equal(1000);  // Default 10%

            // All values should be within uint16 range
            expect(managementFee).to.be.lte(65535);
            expect(performanceFee).to.be.lte(65535);
            expect(withdrawalFee).to.be.lte(65535);
            expect(protocolFee).to.be.lte(65535);
        });
    });

    describe("🧪 Edge Cases and Boundary Conditions", function () {
        it("Should handle minimum fee values", async function () {
            const tx = await vaultFactory.createVault(
                "Boundary Test Vault", "BTV", await usdc.getAddress(),
                await manager.getAddress(), ethers.parseUnits("50000", 6),
                1, 1, { value: ethers.parseEther("0.01") }
            );

            const receipt = await tx.wait();
            expect(receipt?.status).to.equal(1);

            const vaultCreatedEvent = receipt?.logs.find((log: any) => {
                try {
                    const parsedLog = vaultFactory.interface.parseLog(log);
                    return parsedLog?.name === "VaultCreated";
                } catch {
                    return false;
                }
            });

            vaultAddress = vaultFactory.interface.parseLog(vaultCreatedEvent!).args.vault;
            vault = await ethers.getContractAt("Vault", vaultAddress);

            const managementFee = await vault.managementFee();
            const performanceFee = await vault.performanceFee();

            expect(managementFee).to.equal(1);
            expect(performanceFee).to.equal(1);
        });
    });
});
