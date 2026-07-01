// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/HarvestToken.sol";

// Dummy contract to receive ERC-1155 tokens
contract TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }
}

contract HarvestTokenTest is Test {
    HarvestToken public token;
    address public admin = address(0x1);
    address public minter = address(0x2);
    address public agent = address(0x3);
    address public farmer = address(0x4);
    address public buyer = address(0x5);

    function setUp() public {
        token = new HarvestToken(admin);

        vm.prank(admin);
        token.grantRole(keccak256("MINTER_ROLE"), minter);

        vm.prank(admin);
        token.grantRole(keccak256("AGENT_ROLE"), agent);
    }

    function test_Mint_HappyPath() public {
        vm.prank(minter);
        token.mint(farmer, 42, 1, "ipfs://metadata-cid", "0x");

        assertEq(token.balanceOf(farmer, 42), 1);
        assertEq(token.uri(42), "ipfs://metadata-cid");
    }

    function test_Mint_UnauthorizedReverts() public {
        vm.prank(farmer);
        vm.expectRevert();
        token.mint(farmer, 42, 1, "ipfs://metadata-cid", "0x");
    }

    function test_Lock_EnforcesTransferRestrictions() public {
        // Mint unlocked token
        vm.prank(minter);
        token.mint(farmer, 42, 1, "ipfs://metadata", "0x");

        // Lock token
        vm.prank(agent);
        token.markLocked(42);
        assertTrue(token.isLocked(42));

        // Attempt transfer - should revert
        vm.prank(farmer);
        vm.expectRevert("HarvestToken: token is locked as collateral");
        token.safeTransferFrom(farmer, buyer, 42, 1, "0x");

        // Release token
        vm.prank(agent);
        token.markReleased(42);
        assertFalse(token.isLocked(42));

        // Transfer should now work
        TokenReceiver receiver = new TokenReceiver();
        vm.prank(farmer);
        token.safeTransferFrom(farmer, address(receiver), 42, 1, "0x");
        assertEq(token.balanceOf(address(receiver), 42), 1);
    }
}
