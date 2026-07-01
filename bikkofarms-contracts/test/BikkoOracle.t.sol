// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/BikkoOracle.sol";

contract BikkoOracleTest is Test {
    BikkoOracle public oracle;
    address public admin = address(0x1);
    address public updater = address(0x2);
    address public unauthorized = address(0x3);

    function setUp() public {
        oracle = new BikkoOracle(admin);

        vm.prank(admin);
        oracle.grantRole(keccak256("ORACLE_UPDATER_ROLE"), updater);
    }

    function test_InitialState() public {
        assertEq(oracle.cocoaPrice(), 0);
        assertEq(oracle.coffeePrice(), 0);
        assertTrue(oracle.isStale());
    }

    function test_UpdatePrice_HappyPath() public {
        vm.prank(updater);
        oracle.updateCocoaPrice(320); // $3.20/kg
        assertEq(oracle.cocoaPrice(), 320);
        assertEq(oracle.lastUpdated(), block.timestamp);
        assertFalse(oracle.isStale());

        vm.prank(updater);
        oracle.updateCoffeePrice(250);
        assertEq(oracle.coffeePrice(), 250);
    }

    function test_UpdatePrice_UnauthorizedReverts() public {
        vm.prank(unauthorized);
        vm.expectRevert();
        oracle.updateCocoaPrice(300);
    }

    function test_UpdatePrice_DeviationLimitCocoa() public {
        vm.prank(updater);
        oracle.updateCocoaPrice(100);

        // Max increase 50% is 150. Trying 151 should revert.
        vm.prank(updater);
        vm.expectRevert("Oracle: price deviation too large");
        oracle.updateCocoaPrice(151);

        // Max decrease 50% is 50. Trying 49 should revert.
        vm.prank(updater);
        vm.expectRevert("Oracle: price deviation too large");
        oracle.updateCocoaPrice(49);

        // Happy path within limits
        vm.prank(updater);
        oracle.updateCocoaPrice(120);
        assertEq(oracle.cocoaPrice(), 120);
    }

    function test_GetPrice_StalenessGuard() public {
        vm.prank(updater);
        oracle.updateCocoaPrice(320);

        // Advance time by 48h and 1 second
        skip(48 hours + 1);
        assertTrue(oracle.isStale());

        vm.expectRevert("Oracle: price is stale");
        oracle.getCocoaPrice();
    }
}
