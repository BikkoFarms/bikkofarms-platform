// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./HarvestToken.sol";
import "./BikkoOracle.sol";

contract BikkoLendingVault is
    Initializable,
    AccessControlUpgradeable,
    ReentrancyGuard,
    PausableUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20 for IERC20;

    // ─── Roles ──────────────────────────────────────────────────────────────
    bytes32 public constant AGENT_ROLE    = keccak256("AGENT_ROLE");
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE"); // Timelock only

    // ─── State ───────────────────────────────────────────────────────────────
    HarvestToken public harvestToken;
    BikkoOracle  public oracle;
    IERC20       public usdc;

    uint256 public ltvBps;         // Loan-to-value in basis points. Default: 7000 (70%)
    uint256 public maxLoanUsdc;    // Max single loan in USDC cents
    uint256 public loanDuration;   // Seconds until loan is overdue

    struct Loan {
        address farmer;
        uint256 amountUsdcCents;
        uint256 collateralTokenId;
        uint256 appliedAt;
        uint256 dueDate;
        LoanStatus status;
    }

    enum LoanStatus { PENDING, APPROVED, DISBURSED, REPAID, REJECTED, LIQUIDATED }

    mapping(bytes32 => Loan) public loans;      // loanId (bytes32) => Loan
    mapping(address => bool) public farmers;    // registered farmer addresses

    // ─── Events ──────────────────────────────────────────────────────────────
    event FarmerRegistered(address indexed farmer, string village);
    event CollateralLocked(bytes32 indexed loanId, address indexed agent);
    event LoanRepaid(bytes32 indexed loanId, uint256 amountUsdcCents);
    event LoanRejected(bytes32 indexed loanId, string reason);
    event CollateralLiquidated(bytes32 indexed loanId, uint256 tokenId, address indexed to);
    event EmergencyReturn(bytes32 indexed loanId, address indexed farmer, uint256 tokenId);
    event LtvUpdated(uint256 oldBps, uint256 newBps);

    // ─── Initializer (replaces constructor for upgradeable) ─────────────────
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }

    function initialize(
        address adminSafe,
        address timelockAddress,
        address guardianEOA,
        address harvestTokenAddr,
        address oracleAddr,
        address usdcAddr,
        uint256 _ltvBps,
        uint256 _maxLoanUsdc,
        uint256 _loanDuration
    ) external initializer {
        __AccessControl_init();
        __Pausable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, adminSafe);      // Gnosis Safe
        _grantRole(GUARDIAN_ROLE, guardianEOA);          // On-call EOA - pause only
        _grantRole(UPGRADER_ROLE, timelockAddress);      // Timelock - upgrade only

        harvestToken = HarvestToken(harvestTokenAddr);
        oracle = BikkoOracle(oracleAddr);
        usdc   = IERC20(usdcAddr);

        ltvBps       = _ltvBps;       // 7000 = 70%
        maxLoanUsdc  = _maxLoanUsdc;  // e.g. 20000 = $200 USDC
        loanDuration = _loanDuration; // e.g. 90 days
    }

    // ─── Farmer Registration ─────────────────────────────────────────────────
    function registerFarmer(address farmer, string calldata village) external whenNotPaused {
        require(!farmers[farmer], "Vault: already registered");
        farmers[farmer] = true;
        emit FarmerRegistered(farmer, village);
    }

    // ─── Collateral Locking ──────────────────────────────────────────────────
    /// @notice Agent locks a farmer's harvest NFT as collateral for an approved loan.
    function lockCollateral(
        bytes32 loanId,
        address farmer,
        uint256 collateralTokenId,
        uint256 amountUsdcCents,
        uint256 harvestKg,
        string calldata cropType
    ) external onlyRole(AGENT_ROLE) whenNotPaused nonReentrant {
        // ── Checks ──
        require(farmers[farmer], "Vault: farmer not registered");
        require(loans[loanId].farmer == address(0), "Vault: loan ID already exists");
        require(amountUsdcCents > 0 && amountUsdcCents <= maxLoanUsdc, "Vault: amount out of bounds");
        require(!oracle.isStale(), "Vault: oracle price is stale");
        require(harvestToken.balanceOf(farmer, collateralTokenId) == 1, "Vault: farmer does not own token");

        // LTV check
        uint256 pricePerKg = keccak256(bytes(cropType)) == keccak256("cocoa")
            ? oracle.getCocoaPrice()
            : oracle.getCoffeePrice();
        uint256 maxLoan = (harvestKg * pricePerKg * ltvBps) / 10_000;
        require(amountUsdcCents <= maxLoan, "Vault: exceeds LTV limit");

        // ── Effects ──
        loans[loanId] = Loan({
            farmer: farmer,
            amountUsdcCents: amountUsdcCents,
            collateralTokenId: collateralTokenId,
            appliedAt: block.timestamp,
            dueDate: block.timestamp + loanDuration,
            status: LoanStatus.APPROVED
        });

        // ── Interactions ──
        harvestToken.safeTransferFrom(farmer, address(this), collateralTokenId, 1, "");
        harvestToken.markLocked(collateralTokenId);

        emit CollateralLocked(loanId, msg.sender);
    }

    // ─── Loan Rejection ──────────────────────────────────────────────────────
    function rejectLoan(bytes32 loanId, string calldata reason) external onlyRole(AGENT_ROLE) {
        Loan storage loan = loans[loanId];
        require(loan.status == LoanStatus.PENDING, "Vault: not pending");
        // ── Effects ──
        loan.status = LoanStatus.REJECTED;
        emit LoanRejected(loanId, reason);
    }

    // ─── Repayment ───────────────────────────────────────────────────────────
    /// @notice Called by backend after Kotani Pay on-ramp confirms repayment received.
    function repayLoan(bytes32 loanId) external onlyRole(AGENT_ROLE) nonReentrant {
        // ── Checks ──
        Loan storage loan = loans[loanId];
        require(loan.status == LoanStatus.APPROVED || loan.status == LoanStatus.DISBURSED,
                "Vault: loan not active");

        // ── Effects ──
        loan.status = LoanStatus.REPAID;
        uint256 tokenId = loan.collateralTokenId;

        // ── Interactions ──
        harvestToken.markReleased(tokenId);
        harvestToken.safeTransferFrom(address(this), loan.farmer, tokenId, 1, "");

        emit LoanRepaid(loanId, loan.amountUsdcCents);
    }

    // ─── Liquidation (Admin Only) ─────────────────────────────────────────────
    /// @notice Liquidate overdue collateral. Only Gnosis Safe admin.
    function liquidate(bytes32 loanId, address recipient) external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        // ── Checks ──
        Loan storage loan = loans[loanId];
        require(loan.status == LoanStatus.DISBURSED || loan.status == LoanStatus.APPROVED, "Vault: loan not active");
        require(block.timestamp > loan.dueDate, "Vault: loan not yet overdue");
        require(recipient != address(0), "Vault: invalid recipient");

        // ── Effects ──
        loan.status = LoanStatus.LIQUIDATED;
        uint256 tokenId = loan.collateralTokenId;

        // ── Interactions ──
        harvestToken.markReleased(tokenId);
        harvestToken.safeTransferFrom(address(this), recipient, tokenId, 1, "");

        emit CollateralLiquidated(loanId, tokenId, recipient);
    }

    // ─── Emergency Return (Admin Can Help Client) ─────────────────────────────
    /// @notice Admin returns collateral to farmer even if loan is in unusual state.
    ///         Used when: Kotani Pay fails permanently, farmer hardship, system error.
    ///         Requires Gnosis Safe 2-of-3 approval — protects against misuse.
    function emergencyReturn(bytes32 loanId) external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        Loan storage loan = loans[loanId];
        require(loan.farmer != address(0), "Vault: loan not found");
        require(
            loan.status == LoanStatus.APPROVED || loan.status == LoanStatus.DISBURSED,
            "Vault: token not held by vault"
        );

        // ── Effects ──
        uint256 tokenId = loan.collateralTokenId;
        loan.status = LoanStatus.REPAID; // Mark as settled — token is released

        // ── Interactions ──
        harvestToken.markReleased(tokenId);
        harvestToken.safeTransferFrom(address(this), loan.farmer, tokenId, 1, "");

        emit EmergencyReturn(loanId, loan.farmer, tokenId);
    }

    // ─── Admin Configuration ─────────────────────────────────────────────────
    function setLtv(uint256 newBps) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newBps > 0 && newBps <= 8000, "Vault: LTV must be 1-80%");
        emit LtvUpdated(ltvBps, newBps);
        ltvBps = newBps;
    }

    function setMaxLoan(uint256 newMax) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxLoanUsdc = newMax;
    }

    // ─── Emergency Pause ─────────────────────────────────────────────────────
    /// @notice Guardian (single EOA) can pause — useful for on-call incident response.
    function pause()   external onlyRole(GUARDIAN_ROLE) { _pause(); }
    /// @notice Only Gnosis Safe admin can unpause — prevents guardian abuse.
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) { _unpause(); }

    // ─── Upgrade Authorization ───────────────────────────────────────────────
    /// @dev Only Timelock (UPGRADER_ROLE) can authorize upgrades.
    ///      Timelock has a 7-day delay, giving users time to exit.
    function _authorizeUpgrade(address newImpl) internal override onlyRole(UPGRADER_ROLE) {}

    // ─── View Helpers ─────────────────────────────────────────────────────────
    function getLoan(bytes32 loanId) external view returns (Loan memory) {
        return loans[loanId];
    }

    function isOverdue(bytes32 loanId) external view returns (bool) {
        Loan memory loan = loans[loanId];
        return loan.status == LoanStatus.DISBURSED && block.timestamp > loan.dueDate;
    }

    // ─── ERC1155 Receiver Hook Functions ─────────────────────────────────────
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}
