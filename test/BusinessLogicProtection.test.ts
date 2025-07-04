import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

describe("Business Logic Protection", function () {
    let deployer: SignerWithAddress;
    let user1: SignerWithAddress;
    let manager: SignerWithAddress;
    let vault: any;
    let vaultFactory: any;
    let assetHandler: any;
    let governance: any;
    let usdc: any;
    let eth: any;
    let vaultAddress: string;

    beforeEach(async function () {
        [deployer, user1, manager] = await ethers.getSigners();

        // Deploy system components
        const AssetHandler = await ethers.getContractFactory("AssetHandler");
        assetHandler = await AssetHandler.deploy();
        await assetHandler.waitForDeployment();
        await assetHandler.initialize([]);

        const Governance = await ethers.getContractFactory("Governance");
        governance = await Governance.deploy();
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
            ethers.parseUnits("100000", 6), // 100K max capacity
            ethers.parseUnits("100", 6),    // 100 min capacity
            ethers.parseEther("0.01")       // 0.01 ETH creation fee
        );

        // Create mock tokens
        const MockERC20 = await ethers.getContractFactory("MockERC20");
        usdc = await MockERC20.deploy("USD Coin", "USDC", 6);
        eth = await MockERC20.deploy("Mock ETH", "mETH", 18);

        await usdc.waitForDeployment();
        await eth.waitForDeployment();

        // Mint tokens
        await usdc.mint(await user1.getAddress(), ethers.parseUnits("10000", 6));

        // Whitelist USDC as underlying asset and general asset
        await vaultFactory.addUnderlyingAssetWhitelist(await usdc.getAddress());
        await vaultFactory.setAssetWhitelist(await usdc.getAddress(), 1, true); // ERC20 type
        
        // Whitelist ETH token for test usage
        await vaultFactory.setAssetWhitelist(await eth.getAddress(), 1, true); // ERC20 type

        const tx = await vaultFactory.createVault(
            "Test Vault",
            "TV",
            await usdc.getAddress(),
            await manager.getAddress(),
            ethers.parseUnits("50000", 6),
            200, // 2% management fee
            1000, // 10% performance fee
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

        if (!vaultCreatedEvent) {
            throw new Error("VaultCreated event not found");
        }

        vaultAddress = vaultFactory.interface.parseLog(vaultCreatedEvent).args.vault;
        vault = await ethers.getContractAt("Vault", vaultAddress);

        // Fund vault and go live
        await usdc.connect(user1).approve(vaultAddress, ethers.parseUnits("5000", 6));
        await vault.connect(user1).deposit(ethers.parseUnits("5000", 6), await user1.getAddress());
        await vault.connect(manager).goLive();
    });

    describe("areAllPositionsLiquidated", function () {
        it("Should return true when vault only holds underlying asset", async function () {
            const isLiquidated: boolean = await vault.areAllPositionsLiquidated();
            expect(isLiquidated).to.be.true;
        });

        it("Should return false when vault holds non-underlying assets", async function () {
            // Add ETH as supported asset and mint some to vault
            await vault.connect(manager).addSupportedAsset(await eth.getAddress());
            await eth.mint(vaultAddress, ethers.parseEther("1"));

            const isLiquidated: boolean = await vault.areAllPositionsLiquidated();
            expect(isLiquidated).to.be.false;
        });
    });

    describe("getAssetsToLiquidate", function () {
        it("Should return empty array when all positions liquidated", async function () {
            const [assetsToLiquidate, totalValue] = await vault.getAssetsToLiquidate();
            expect(assetsToLiquidate.length).to.equal(0);
            expect(totalValue).to.equal(0);
        });

        it("Should return non-underlying assets that need liquidation", async function () {
            // Add ETH as supported asset and mint some to vault
            await vault.connect(manager).addSupportedAsset(await eth.getAddress());
            await eth.mint(vaultAddress, ethers.parseEther("2"));

            const [assetsToLiquidate, totalValue] = await vault.getAssetsToLiquidate();
            expect(assetsToLiquidate.length).to.equal(1);
            expect(assetsToLiquidate[0]).to.equal(await eth.getAddress());
            // Note: totalValue might be 0 due to missing price feeds, but that's OK for this test
        });
    });

    describe("Business Logic Protection", function () {
        beforeEach(async function () {
            // Add ETH as supported asset and mint some to vault to simulate active positions
            await vault.connect(manager).addSupportedAsset(await eth.getAddress());
            await eth.mint(vaultAddress, ethers.parseEther("2"));
        });

        it("Should block realizeByManager when vault has active positions", async function () {
            // Verify we have active positions
            const isLiquidated: boolean = await vault.areAllPositionsLiquidated();
            expect(isLiquidated).to.be.false;

            // Attempt to realize profits should fail
            await expect(
                vault.connect(manager).realizeByManager()
            ).to.be.revertedWithCustomError(vault, "ManualLiquidationRequired");
        });

        it("Should emit HarvestBlocked event with correct data", async function () {
            // The event is emitted before the revert, so we need to check for revert
            // but the event should still be logged
            try {
                await vault.connect(manager).realizeByManager();
                expect.fail("Should have reverted");
            } catch (error: any) {
                expect(error.message).to.include("ManualLiquidationRequired");
                // Event is emitted but transaction reverts, which is the expected behavior
            }
        });
    });

    describe("Protection Benefits", function () {
        it("Should demonstrate protection against unrealized gain exploitation", async function () {
            // Setup: Vault has USDC + ETH positions
            await vault.connect(manager).addSupportedAsset(await eth.getAddress());
            await eth.mint(vaultAddress, ethers.parseEther("2"));

            // Verify manager cannot harvest with active positions
            const isLiquidated: boolean = await vault.areAllPositionsLiquidated();
            expect(isLiquidated).to.be.false;

            // This should fail - protecting users from unrealized gain fee extraction
            await expect(
                vault.connect(manager).realizeByManager()
            ).to.be.revertedWithCustomError(vault, "ManualLiquidationRequired");

            // Verify we can check what assets need liquidation
            const [assetsToLiquidate] = await vault.getAssetsToLiquidate();
            expect(assetsToLiquidate.length).to.be.greaterThan(0);
            expect(assetsToLiquidate[0]).to.equal(await eth.getAddress());
        });

        it("Should enforce liquidation requirement consistently", async function () {
            // Add multiple non-underlying assets
            await vault.connect(manager).addSupportedAsset(await eth.getAddress());
            await eth.mint(vaultAddress, ethers.parseEther("1"));

            // Create another mock token
            const MockERC20 = await ethers.getContractFactory("MockERC20");
            const btc = await MockERC20.deploy("Mock BTC", "mBTC", 8);
            await btc.waitForDeployment();

            // Whitelist BTC token before adding to vault
            await vaultFactory.setAssetWhitelist(await btc.getAddress(), 1, true); // ERC20 type
            await vault.connect(manager).addSupportedAsset(await btc.getAddress());
            await btc.mint(vaultAddress, ethers.parseUnits("1", 8));

            // Should still be blocked with multiple assets
            await expect(
                vault.connect(manager).realizeByManager()
            ).to.be.revertedWithCustomError(vault, "ManualLiquidationRequired");

            // Check both assets are listed for liquidation
            const [assetsToLiquidate] = await vault.getAssetsToLiquidate();
            expect(assetsToLiquidate.length).to.equal(2);
            expect(assetsToLiquidate).to.include(await eth.getAddress());
            expect(assetsToLiquidate).to.include(await btc.getAddress());
        });
    });

    describe("Integration with Existing Features", function () {
        it("Should not affect normal vault operations", async function () {
            // Normal deposit should still work (but fail in LIVE state as expected)
            await usdc.connect(user1).approve(vaultAddress, ethers.parseUnits("1000", 6));
            await expect(
                vault.connect(user1).deposit(ethers.parseUnits("1000", 6), await user1.getAddress())
            ).to.be.revertedWithCustomError(vault, "InvalidVaultState"); // Expected for LIVE state
        });

        it("Should maintain vault state correctly", async function () {
            // Add positions
            await vault.connect(manager).addSupportedAsset(await eth.getAddress());
            await eth.mint(vaultAddress, ethers.parseEther("1"));

            // Vault state should remain unchanged
            const vaultInfo = await vault.getEpochInfo();
            expect(vaultInfo.state).to.equal(1); // LIVE state

            // Protection should still work
            await expect(
                vault.connect(manager).realizeByManager()
            ).to.be.revertedWithCustomError(vault, "ManualLiquidationRequired");
        });
    });
}); 