// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract BikkoOracle is AccessControl {
    bytes32 public constant ORACLE_UPDATER_ROLE = keccak256("ORACLE_UPDATER_ROLE");

    uint256 public cocoaPrice;  // in USD cents per kg (e.g. 320 = $3.20/kg)
    uint256 public coffeePrice; // in USD cents per kg
    uint256 public lastUpdated;

    event PriceUpdated(string indexed cropType, uint256 newPrice);

    constructor(address adminSafe) {
        _grantRole(DEFAULT_ADMIN_ROLE, adminSafe);
        _grantRole(ORACLE_UPDATER_ROLE, adminSafe);
    }

    function updateCocoaPrice(uint256 newPrice) external onlyRole(ORACLE_UPDATER_ROLE) {
        require(newPrice > 0, "Oracle: price must be non-zero");
        if (cocoaPrice > 0) {
            uint256 maxDeviation = (cocoaPrice * 5000) / 10000; // 50% deviation limit
            require(
                newPrice >= cocoaPrice - maxDeviation && newPrice <= cocoaPrice + maxDeviation,
                "Oracle: price deviation too large"
            );
        }
        cocoaPrice = newPrice;
        lastUpdated = block.timestamp;
        emit PriceUpdated("cocoa", newPrice);
    }

    function updateCoffeePrice(uint256 newPrice) external onlyRole(ORACLE_UPDATER_ROLE) {
        require(newPrice > 0, "Oracle: price must be non-zero");
        if (coffeePrice > 0) {
            uint256 maxDeviation = (coffeePrice * 5000) / 10000; // 50% deviation limit
            require(
                newPrice >= coffeePrice - maxDeviation && newPrice <= coffeePrice + maxDeviation,
                "Oracle: price deviation too large"
            );
        }
        coffeePrice = newPrice;
        lastUpdated = block.timestamp;
        emit PriceUpdated("coffee", newPrice);
    }

    function getCocoaPrice() external view returns (uint256) {
        require(!isStale(), "Oracle: price is stale");
        return cocoaPrice;
    }

    function getCoffeePrice() external view returns (uint256) {
        require(!isStale(), "Oracle: price is stale");
        return coffeePrice;
    }

    function isStale() public view returns (bool) {
        if (lastUpdated == 0) return true;
        return block.timestamp > lastUpdated + 48 hours;
    }
}
