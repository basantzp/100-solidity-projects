// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {EIP712MetaTransactions} from "../src/05_Cryptographic/EIP712MetaTransactions.sol";

contract TargetRecipient {
    uint256 public counter;
    address public lastCaller;

    function increment() external {
        counter += 1;
        // In ERC-2771 context, sender is appended in last 20 bytes of calldata
        if (msg.data.length >= 20) {
            bytes memory senderBytes = new bytes(20);
            for (uint256 i = 0; i < 20; i++) {
                senderBytes[i] = msg.data[msg.data.length - 20 + i];
            }
            lastCaller = abi.decode(abi.encodePacked(new bytes(12), senderBytes), (address));
        } else {
            lastCaller = msg.sender;
        }
    }
}

contract EIP712MetaTransactionsTest is Test {
    EIP712MetaTransactions public forwarder;
    TargetRecipient public target;

    uint256 internal userPrivateKey = 0xA11CE;
    address internal user;
    address internal relayer = address(0x999);

    function setUp() public {
        user = vm.addr(userPrivateKey);
        forwarder = new EIP712MetaTransactions("MinimalForwarder", "1.0");
        target = new TargetRecipient();
    }

    function test_RelayerExecutesMetaTransaction() public {
        bytes memory callData = abi.encodeWithSelector(TargetRecipient.increment.selector);

        EIP712MetaTransactions.ForwardRequest memory req = EIP712MetaTransactions.ForwardRequest({
            from: user, to: address(target), value: 0, gas: 100000, nonce: 0, data: callData
        });

        bytes32 structHash = keccak256(
            abi.encode(forwarder.TYPE_HASH(), req.from, req.to, req.value, req.gas, req.nonce, keccak256(req.data))
        );

        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", forwarder.DOMAIN_SEPARATOR(), structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        // Relayer submits transaction on behalf of user
        vm.prank(relayer);
        (bool success,) = forwarder.execute(req, signature);

        assertTrue(success);
        assertEq(target.counter(), 1);
        assertEq(forwarder.nonces(user), 1);
    }
}
