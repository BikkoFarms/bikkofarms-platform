# Skill Manual: Testing & Validation

Testing strategies, unit test schemas, and validation guidelines for BikkoChain components.

---

## 🎯 Purpose
To enforce comprehensive testing standards that guarantee functional stability, prevent regressions, and verify logic correctness across the smart contracts, APIs, and user interfaces before mainnet deployment.

---

## 💡 Best Practices

* **Test-Driven Design:** Write unit tests alongside logic implementation.
* **Component Testing:** Use React Testing Library to test user behaviors rather than component implementation details.
* **API Testing:** Write integration tests using Supertest/Jest to hit REST/USSD API endpoints and verify database side-effects.
* **Deterministic Contract Testing:** Run Solidity tests using Foundry (forge test), checking all failure modes, reentrancy vectors, fuzzing inputs, and boundary gas limits.

---

## 🛑 Constraints

* **100% Core Coverage:** Critical code blocks (such as payment disbursements, loan escrow locking, interest calculations) must have 100% test coverage.
* **Isolation:** Test suites must not share state. Databases must be truncated or transaction-rolled back between test runs.
* **No Network Calls:** Mock all external API endpoints (e.g. Kotani Pay, Chainlink, Twilio) inside unit and integration tests.

---

## 📐 Code Conventions

* **Descriptive Test Blocks:** Use descriptive test function names in Solidity following the `test[State]_[Behavior]` convention.
  ```solidity
  contract BikkoLendingVaultTest is Test {
      function testLockCollateral_LocksCollateral() public {
          // Arrange
          // Act
          // Assert
      }
      function testLockCollateral_RevertsIfNotAgent() public {
          // Expect revert...
      }
  }
  ```
* **Arrange-Act-Assert Pattern:** Structure test bodies with clear setup, action, and assertions.

---

## ⚠️ Common Pitfalls

* **Brittle UI Tests:** Using absolute CSS selectors (e.g. `.form > div:nth-child(2) > button`) instead of roles (`screen.getByRole('button', { name: /submit/i })`).
* **Unmocked Timers:** Writing tests that wait for real-world intervals. Use fake timers (`jest.useFakeTimers()`).
* **Hardcoded Blockchain Nonces:** Failing to reset local EVM state, leading to nonces out-of-sync during batch runs.

---

## ✅ Acceptance Criteria

1. **Test Suites Passing:** All unit tests must pass locally and in the GitHub CI pipeline.
2. **Coverage Thresholds:** Minimum 85% statement coverage across application repositories, and 100% coverage on financial contracts.
3. **No Flakiness:** All tests must run deterministically with zero intermittent failures.
