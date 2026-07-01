// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../src/BikkoLendingVault.sol";
import "../src/HarvestToken.sol";
import "../src/BikkoOracle.sol";

// Mock USDC Contract
contract MockUSDC is ERC20 {
    constructor() ERC20("Mock USDC", "mUSDC") {
        _mint(msg.sender, 1000000 * 10**6);
    }
    
    function decimals() public pure override returns (uint8) {
        return 6;
    }
}

contract BikkoLendingVaultTest is Test {
    BikkoLendingVault public vault;
    HarvestToken public token;
    BikkoOracle public oracle;
    MockUSDC public usdc;

    address public admin = address(0x1);
    address public timelock = address(0x2);
    address public guardian = address(0x3);
    address public agent = address(0x4);
    address public minter = address(0x5);
    address public updater = address(0x6);
    
    address public farmer = address(0x7);
    address public liquidatorRecipient = address(0x8);

    function setUp() public {
        // Deploy supporting assets
        vm.startPrank(admin);
        usdc = new MockUSDC();
        token = new HarvestToken(admin);
        oracle = new BikkoOracle(admin);

        // Set roles on assets
        token.grantRole(token.MINTER_ROLE(), minter);
        token.grantRole(token.AGENT_ROLE(), agent);
        oracle.grantRole(oracle.ORACLE_UPDATER_ROLE(), updater);

        // Deploy UUPS Proxy for Vault
        BikkoLendingVault implementation = new BikkoLendingVault();
        bytes memory initData = abi.encodeWithSelector(
            BikkoLendingVault.initialize.selector,
            admin,
            timelock,
            guardian,
            address(token),
            address(oracle),
            address(usdc),
            7000,          // LTV 70%
            20000,         // Max single loan ($200 USDC cents)
            90 days        // Default duration
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        vault = BikkoLendingVault(address(proxy));

        // Grant roles
        token.grantRole(token.AGENT_ROLE(), address(vault));
        vault.grantRole(vault.AGENT_ROLE(), agent);
        vm.stopPrank();

        // Seed prices
        vm.prank(updater);
        oracle.updateCocoaPrice(320); // $3.20/kg
    }

    function test_InitialState() public {
        assertEq(vault.ltvBps(), 7000);
        assertEq(vault.maxLoanUsdc(), 20000);
        assertEq(vault.loanDuration(), 90 days);
    }

    function test_RegisterFarmer() public {
        vm.prank(agent);
        vault.registerFarmer(farmer, "Tepa");
        assertTrue(vault.farmers(farmer));
    }

    function test_LockCollateral_HappyPath() public {
        // Register farmer
        vm.prank(agent);
        vault.registerFarmer(farmer, "Tepa");

        // Mint harvest token to farmer
        vm.prank(minter);
        token.mint(farmer, 42, 1, "ipfs://harvest-metadata", "0x");

        // Approve vault to transfer the token
        vm.prank(farmer);
        token.setApprovalForAll(address(vault), true);

        // Lock collateral: 500kg harvest × $3.20 = $1600 × 70% LTV = $1120 max. Asking for $150 (15000 cents).
        bytes32 loanId = keccak256("loan-1");
        vm.prank(agent);
        vault.lockCollateral(loanId, farmer, 42, 15000, 500, "cocoa");

        // Assertions
        assertTrue(token.isLocked(42));
        assertEq(token.balanceOf(address(vault), 42), 1);
        
        BikkoLendingVault.Loan memory loan = vault.getLoan(loanId);
        assertEq(loan.farmer, farmer);
        assertEq(loan.amountUsdcCents, 15000);
        assertEq(loan.collateralTokenId, 42);
        assertEq(uint(loan.status), uint(BikkoLendingVault.LoanStatus.APPROVED));
    }

    function test_LockCollateral_LtvLimitExceededReverts() public {
        vm.prank(agent);
        vault.registerFarmer(farmer, "Tepa");

        vm.prank(minter);
        token.mint(farmer, 42, 1, "ipfs://metadata", "0x");

        vm.prank(farmer);
        token.setApprovalForAll(address(vault), true);

        // 50kg harvest × $3.20 = $160 × 70% LTV = $112 max. Asking for $150 (15000 cents) should revert.
        bytes32 loanId = keccak256("loan-2");
        vm.prank(agent);
        vm.expectRevert("Vault: exceeds LTV limit");
        vault.lockCollateral(loanId, farmer, 42, 15000, 50, "cocoa");
    }

    function test_RepayLoan_HappyPath() public {
        // Arrange: set up a locked collateral loan
        vm.prank(agent);
        vault.registerFarmer(farmer, "Tepa");

        vm.prank(minter);
        token.mint(farmer, 42, 1, "ipfs://metadata", "0x");

        vm.prank(farmer);
        token.setApprovalForAll(address(vault), true);

        bytes32 loanId = keccak256("loan-3");
        vm.prank(agent);
        vault.lockCollateral(loanId, farmer, 42, 10000, 500, "cocoa");

        // Act: Repay loan
        vm.prank(agent);
        vault.repayLoan(loanId);

        // Assert: collateral is released back to farmer
        assertFalse(token.isLocked(42));
        assertEq(token.balanceOf(farmer, 42), 1);
        
        BikkoLendingVault.Loan memory loan = vault.getLoan(loanId);
        assertEq(uint(loan.status), uint(BikkoLendingVault.LoanStatus.REPAID));
    }

    function test_Liquidate_OverdueLoan() public {
        vm.prank(agent);
        vault.registerFarmer(farmer, "Tepa");

        vm.prank(minter);
        token.mint(farmer, 42, 1, "ipfs://metadata", "0x");

        vm.prank(farmer);
        token.setApprovalForAll(address(vault), true);

        bytes32 loanId = keccak256("loan-4");
        vm.prank(agent);
        vault.lockCollateral(loanId, farmer, 42, 10000, 500, "cocoa");

        // Advance time past due date (90 days)
        skip(90 days + 1);

        // Liquidate
        vm.prank(admin);
        vault.liquidate(loanId, liquidatorRecipient);

        // Assert: collateral transferred to recipient
        assertEq(token.balanceOf(liquidatorRecipient, 42), 1);
        assertFalse(token.isLocked(42));
    }

    function test_EmergencyReturn() public {
        vm.prank(agent);
        vault.registerFarmer(farmer, "Tepa");

        vm.prank(minter);
        token.mint(farmer, 42, 1, "ipfs://metadata", "0x");

        vm.prank(farmer);
        token.setApprovalForAll(address(vault), true);

        bytes32 loanId = keccak256("loan-5");
        vm.prank(agent);
        vault.lockCollateral(loanId, farmer, 42, 10000, 500, "cocoa");

        // Emergency return by admin
        vm.prank(admin);
        vault.emergencyReturn(loanId);

        // Assert: collateral returned to farmer
        assertEq(token.balanceOf(farmer, 42), 1);
        assertFalse(token.isLocked(42));
    }
}
