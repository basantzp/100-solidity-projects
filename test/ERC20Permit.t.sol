// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {ERC20Permit} from "../src/01_Tokens/ERC20Permit.sol";

contract MockERC20Permit is ERC20Permit {
    constructor() ERC20Permit("Mock Token", "MCK", 18) {
        _mint(msg.sender, 1_000_000e18);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract ERC20PermitTest is Test {
    MockERC20Permit token;
    address alice = address(0x1);
    address bob = address(0x2);

    uint256 ownerPrivateKey = 0xA11CE;
    address owner;

    function setUp() public {
        token = new MockERC20Permit();
        owner = vm.addr(ownerPrivateKey);
        token.mint(owner, 10_000e18);
    }

    function test_InitialSupplyAndMetadata() public view {
        assertEq(token.name(), "Mock Token");
        assertEq(token.symbol(), "MCK");
        assertEq(token.decimals(), 18);
    }

    function test_Transfer() public {
        token.mint(alice, 100e18);
        vm.prank(alice);
        token.transfer(bob, 40e18);

        assertEq(token.balanceOf(alice), 60e18);
        assertEq(token.balanceOf(bob), 40e18);
    }

    function test_TransferFrom_WithApproval() public {
        token.mint(alice, 100e18);
        vm.prank(alice);
        token.approve(bob, 50e18);

        vm.prank(bob);
        token.transferFrom(alice, bob, 30e18);

        assertEq(token.balanceOf(alice), 70e18);
        assertEq(token.balanceOf(bob), 30e18);
        assertEq(token.allowance(alice, bob), 20e18);
    }

    function test_Permit_GaslessApproval() public {
        uint256 value = 500e18;
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = token.nonces(owner);

        bytes32 structHash = keccak256(abi.encode(token.PERMIT_TYPEHASH(), owner, bob, value, nonce, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", token.DOMAIN_SEPARATOR(), structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        token.permit(owner, bob, value, deadline, v, r, s);

        assertEq(token.allowance(owner, bob), value);
        assertEq(token.nonces(owner), 1);
    }

    function testFuzz_Transfer(uint256 amount) public {
        vm.assume(amount > 0 && amount <= 10_000e18);
        vm.prank(owner);
        token.transfer(alice, amount);
        assertEq(token.balanceOf(alice), amount);
    }
}
