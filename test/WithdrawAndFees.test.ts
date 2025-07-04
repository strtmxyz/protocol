import { ethers } from "hardhat";
import { expect } from "chai";
import { Signer } from "ethers";
import { 
    Vault, 
    VaultFactory, 
    AssetHandler, 
    Governance,
    MockERC20 
} from "../types";

describe("Withdraw and Fees Comprehensive Tests", function () {
    let deployer: Signer;
    let manager: Signer;
    let user1: Signer;
    let user2: Signer;
    let user3: Signer;
    let protocolTreasury: Signer;

    let vault: Vault;
    let vaultFactory: VaultFactory;
    let assetHandler: AssetHandler;
    let governance: Governance;
    let usdc: MockERC20;
    let vaultAddress: string;

    before(async function () {
        [deployer, manager, user1, user2, user3, protocolTreasury] = await ethers.getSigners();

        // Deploy core contracts
        const AssetHandler = await ethers.getContractFactory("AssetHandler");
        assetHandler = await AssetHandler.deploy() as any;
        await assetHandler.waitForDeployment();

        const Governance = await ethers.getContractFactory("Governance");
        governance = await Governance.deploy() as any;
        await governance.waitForDeployment();

        const vaultImplementation = await ethers.deployContract("Vault");
        await vaultImplementation.waitForDeployment();

        const VaultFactory = await ethers.getContractFactory("VaultFactory");
        vaultFactory = await VaultFactory.deploy() as any;
        await vaultFactory.waitForDeployment();
        
        await vaultFactory.initialize(
            await assetHandler.getAddress(),
            await protocolTreasury.getAddress(),
            await governance.getAddress()
        );
        await vaultFactory.updateVaultImplementation(await vaultImplementation.getAddress());

        await vaultFactory.setFactorySettings(
            ethers.parseUnits("100000", 6),
            ethers.parseUnits("100", 6),
            ethers.parseEther("0.01")
        );

        // Create USDC token
        const MockERC20 = await ethers.getContractFactory("MockERC20");
        usdc = await MockERC20.deploy("USD Coin", "USDC", 6) as any;
        await usdc.waitForDeployment();

        // Mint USDC to users
        await usdc.mint(await user1.getAddress(), ethers.parseUnits("50000", 6));
        await usdc.mint(await user2.getAddress(), ethers.parseUnits("30000", 6));
        await usdc.mint(await user3.getAddress(), ethers.parseUnits("20000", 6));

        // Whitelist USDC as underlying asset and general asset
        await vaultFactory.addUnderlyingAssetWhitelist(await usdc.getAddress());
        await vaultFactory.setAssetWhitelist(await usdc.getAddress(), 1, true); // ERC20 type

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

        if (!vaultCreatedEvent) throw new Error("VaultCreated event not found");
        const parsedEvent = vaultFactory.interface.parseLog(vaultCreatedEvent);
        if (!parsedEvent) throw new Error("Failed to parse VaultCreated event");
        vaultAddress = parsedEvent.args.vault;
        vault = await ethers.getContractAt("Vault", vaultAddress) as any;

        // Setup vault for testing
        await usdc.connect(user1).approve(vaultAddress, ethers.parseUnits("10000", 6));
        await usdc.connect(user2).approve(vaultAddress, ethers.parseUnits("10000", 6));
        await usdc.connect(user3).approve(vaultAddress, ethers.parseUnits("10000", 6));

        // Initial deposits
        await vault.connect(user1).deposit(ethers.parseUnits("8000", 6), await user1.getAddress());
        await vault.connect(user2).deposit(ethers.parseUnits("6000", 6), await user2.getAddress());
        await vault.connect(user3).deposit(ethers.parseUnits("4000", 6), await user3.getAddress());

        // Go live
        await vault.connect(manager).goLive();
    });

    describe("Basic Withdrawal Fee Collection", function () {
        it("Should collect withdrawal fees correctly", async function () {
            const withdrawAmount = ethers.parseUnits("1000", 6);
            const withdrawalFee = await vault.withdrawalFee();
            const expectedFee = (withdrawAmount * withdrawalFee) / 10000n;
            const expectedAfterFee = withdrawAmount - expectedFee;

            const user1BalanceBefore = await usdc.balanceOf(await user1.getAddress());
            const managerBalanceBefore = await usdc.balanceOf(await manager.getAddress());

            await vault.connect(user1).withdraw(withdrawAmount, await user1.getAddress(), await user1.getAddress());

            const user1BalanceAfter = await usdc.balanceOf(await user1.getAddress());
            const managerBalanceAfter = await usdc.balanceOf(await manager.getAddress());

            expect(user1BalanceAfter - user1BalanceBefore).to.equal(expectedAfterFee);
            expect(managerBalanceAfter - managerBalanceBefore).to.equal(expectedFee);
        });

        it("Should preview withdrawal fees correctly", async function () {
            const withdrawAmount = ethers.parseUnits("2000", 6);
            const withdrawalFee = await vault.withdrawalFee();
            
            const previewShares = await vault.previewWithdraw(withdrawAmount);
            const totalAssetsBeforeWithdraw = await vault.totalAssets();
            const totalSupplyBeforeWithdraw = await vault.totalSupply();
            
            const amountWithFee = withdrawAmount + (withdrawAmount * withdrawalFee) / 10000n;
            const expectedShares = (amountWithFee * totalSupplyBeforeWithdraw) / totalAssetsBeforeWithdraw;
            
            expect(previewShares).to.be.closeTo(expectedShares, ethers.parseUnits("10", 6));
        });
    });

    describe("Auto-Realization on Withdraw", function () {
        beforeEach(async function () {
            const profit = ethers.parseUnits("2000", 6);
            await usdc.mint(vaultAddress, profit);
        });

        it("Should auto-realize profits on first withdrawal", async function () {
            const managerBalanceBefore = await usdc.balanceOf(await manager.getAddress());
            const protocolBalanceBefore = await usdc.balanceOf(await protocolTreasury.getAddress());

            const [isRealized, , , hasUnrealizedProfits] = await vault.getAutoRealizationStatus();
            expect(isRealized).to.be.false;
            expect(hasUnrealizedProfits).to.be.true;

            await expect(
                vault.connect(user1).withdraw(ethers.parseUnits("500", 6), await user1.getAddress(), await user1.getAddress())
            ).to.emit(vault, "AutoRealizationTriggered");

            const managerBalanceAfter = await usdc.balanceOf(await manager.getAddress());
            const protocolBalanceAfter = await usdc.balanceOf(await protocolTreasury.getAddress());

            expect(managerBalanceAfter).to.be.gt(managerBalanceBefore);
            expect(protocolBalanceAfter).to.be.gt(protocolBalanceBefore);

            const [isRealizedAfter] = await vault.getAutoRealizationStatus();
            expect(isRealizedAfter).to.be.true;
        });

        it("Should NOT auto-realize on subsequent withdrawals", async function () {
            await vault.connect(user1).withdraw(ethers.parseUnits("500", 6), await user1.getAddress(), await user1.getAddress());

            const managerBalanceBefore = await usdc.balanceOf(await manager.getAddress());
            const protocolBalanceBefore = await usdc.balanceOf(await protocolTreasury.getAddress());

            await expect(
                vault.connect(user2).withdraw(ethers.parseUnits("300", 6), await user2.getAddress(), await user2.getAddress())
            ).to.not.emit(vault, "AutoRealizationTriggered");

            const managerBalanceAfter = await usdc.balanceOf(await manager.getAddress());
            const protocolBalanceAfter = await usdc.balanceOf(await protocolTreasury.getAddress());

            const withdrawalFee = await vault.withdrawalFee();
            const expectedWithdrawalFee = (ethers.parseUnits("300", 6) * withdrawalFee) / 10000n;
            
            expect(managerBalanceAfter - managerBalanceBefore).to.equal(expectedWithdrawalFee);
            expect(protocolBalanceAfter).to.equal(protocolBalanceBefore);
        });
    });

    describe("Fee Calculations", function () {
        beforeEach(async function () {
            const profit = ethers.parseUnits("5000", 6);
            await usdc.mint(vaultAddress, profit);
            
            // Fast forward time to reset cooldown if needed
            await ethers.provider.send("evm_increaseTime", [60 * 60 + 1]); // 1 hour + 1 second
            await ethers.provider.send("evm_mine", []);
        });

        it("Should calculate performance fees correctly", async function () {
            // Factory owner (deployer) can update vault fees via factory
            await vaultFactory.connect(deployer).updateVaultFees(
                vaultAddress,
                0,    // 0% management fee
                2000, // 20% performance fee  
                0,    // 0% withdrawal fee
                2500  // 25% protocol fee share
            );

            // Check initial state to ensure we have unrealized profits
            const [isRealized, , , hasUnrealizedProfits] = await vault.getAutoRealizationStatus();
            expect(hasUnrealizedProfits).to.be.true;

            const managerBalanceBefore = await usdc.balanceOf(await manager.getAddress());
            const protocolBalanceBefore = await usdc.balanceOf(await protocolTreasury.getAddress());

            // Trigger auto-realization
            await expect(
                vault.connect(user1).withdraw(ethers.parseUnits("100", 6), await user1.getAddress(), await user1.getAddress())
            ).to.emit(vault, "AutoRealizationTriggered");

            const managerBalanceAfter = await usdc.balanceOf(await manager.getAddress());
            const protocolBalanceAfter = await usdc.balanceOf(await protocolTreasury.getAddress());

            const managerPerformanceFee = managerBalanceAfter - managerBalanceBefore;
            const protocolFee = protocolBalanceAfter - protocolBalanceBefore;

            console.log("Manager fee:", ethers.formatUnits(managerPerformanceFee, 6));
            console.log("Protocol fee:", ethers.formatUnits(protocolFee, 6));

            expect(protocolFee).to.be.gt(0);
            expect(managerPerformanceFee).to.be.gt(0);
            expect(managerPerformanceFee).to.be.gt(protocolFee);
        });
    });

    describe("Multiple Withdrawals Consistency", function () {
        beforeEach(async function () {
            await usdc.mint(vaultAddress, ethers.parseUnits("3000", 6));
        });

        it("Should handle multiple withdrawals consistently", async function () {
            const withdrawAmount = ethers.parseUnits("400", 6);
            
            const user1SharesBefore = await vault.balanceOf(await user1.getAddress());
            const user2SharesBefore = await vault.balanceOf(await user2.getAddress());

            await vault.connect(user1).withdraw(withdrawAmount, await user1.getAddress(), await user1.getAddress());
            await vault.connect(user2).withdraw(withdrawAmount, await user2.getAddress(), await user2.getAddress());

            const user1SharesAfter = await vault.balanceOf(await user1.getAddress());
            const user2SharesAfter = await vault.balanceOf(await user2.getAddress());

            const user1SharesLost = user1SharesBefore - user1SharesAfter;
            const user2SharesLost = user2SharesBefore - user2SharesAfter;

            const expectedShares = await vault.previewWithdraw(withdrawAmount);
            expect(user1SharesLost).to.be.closeTo(expectedShares, ethers.parseUnits("50", 6));
            expect(user2SharesLost).to.be.closeTo(expectedShares, ethers.parseUnits("50", 6));
        });
    });

    describe("Cooldown Behavior", function () {
        beforeEach(async function () {
            await usdc.mint(vaultAddress, ethers.parseUnits("1000", 6));
        });

        it("Should respect cooldown period", async function () {
            await vault.connect(user1).withdraw(ethers.parseUnits("100", 6), await user1.getAddress(), await user1.getAddress());

            const [isRealized, , timeToNext] = await vault.getAutoRealizationStatus();
            expect(isRealized).to.be.true;
            expect(timeToNext).to.be.gt(0);

            const [needsRealize, reason] = await vault.shouldManagerRealize();
            expect(needsRealize).to.be.false;
            expect(reason).to.include("cooldown");
        });

        it("Should reset after cooldown period", async function () {
            await vault.connect(user1).withdraw(ethers.parseUnits("100", 6), await user1.getAddress(), await user1.getAddress());

            await ethers.provider.send("evm_increaseTime", [60 * 60 + 1]);
            await ethers.provider.send("evm_mine", []);

            await usdc.mint(vaultAddress, ethers.parseUnits("500", 6));

            const [, , timeToNext, hasUnrealizedProfits] = await vault.getAutoRealizationStatus();
            expect(timeToNext).to.equal(0);
            expect(hasUnrealizedProfits).to.be.true;

            await expect(
                vault.connect(user2).withdraw(ethers.parseUnits("200", 6), await user2.getAddress(), await user2.getAddress())
            ).to.emit(vault, "AutoRealizationTriggered");
        });
    });

    describe("Edge Cases", function () {
        it("Should handle withdrawals when no profits exist", async function () {
            const vaultBalanceBefore = await usdc.balanceOf(vaultAddress);
            
            await expect(
                vault.connect(user1).withdraw(ethers.parseUnits("500", 6), await user1.getAddress(), await user1.getAddress())
            ).to.not.emit(vault, "AutoRealizationTriggered");

            const vaultBalanceAfter = await usdc.balanceOf(vaultAddress);
            expect(vaultBalanceBefore - vaultBalanceAfter).to.equal(ethers.parseUnits("500", 6));
        });

        it("Should handle very small withdrawals", async function () {
            await usdc.mint(vaultAddress, ethers.parseUnits("100", 6));
            
            // Fast forward time to reset cooldown
            await ethers.provider.send("evm_increaseTime", [60 * 60 + 1]);
            await ethers.provider.send("evm_mine", []);

            const withdrawAmount = ethers.parseUnits("1", 6);
            
            // After fast forwarding, the state should reset, so auto-realization should trigger
            await expect(
                vault.connect(user1).withdraw(withdrawAmount, await user1.getAddress(), await user1.getAddress())
            ).to.emit(vault, "AutoRealizationTriggered");
        });
    });

    describe("Fee Impact Preview", function () {
        beforeEach(async function () {
            await usdc.mint(vaultAddress, ethers.parseUnits("3000", 6));
        });

        it("Should preview withdrawal impact correctly", async function () {
            const withdrawAmount = ethers.parseUnits("500", 6);
            
            // Check current auto-realization status first
            const [isRealized, , , hasUnrealizedProfits] = await vault.getAutoRealizationStatus();
            console.log("Is realized:", isRealized, "Has unrealized profits:", hasUnrealizedProfits);
            
            const [willAutoRealize, estimatedFees] = await vault.previewWithdrawalImpact(withdrawAmount);
            
            console.log("Will auto-realize:", willAutoRealize, "Estimated fees:", ethers.formatUnits(estimatedFees, 6));
            
            // Only expect auto-realization if we have unrealized profits and not already realized
            if (hasUnrealizedProfits && !isRealized) {
                expect(willAutoRealize).to.be.true;
                expect(estimatedFees).to.be.gt(0);
            } else {
                expect(willAutoRealize).to.be.false;
                expect(estimatedFees).to.equal(0);
            }
        });

        it("Should show no impact when already realized", async function () {
            await vault.connect(user1).withdraw(ethers.parseUnits("100", 6), await user1.getAddress(), await user1.getAddress());
            
            const [willAutoRealize, estimatedFees] = await vault.previewWithdrawalImpact(ethers.parseUnits("500", 6));
            
            expect(willAutoRealize).to.be.false;
            expect(estimatedFees).to.equal(0);
        });
    });
}); 