// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {AgentAttestRegistry} from "../contracts/AgentAttestRegistry.sol";

/// @notice Fork test against the REAL Agent ID contract on BNB Chain mainnet.
///         Run with:  forge test --match-contract ForkGateTest --fork-url https://bsc-dataseed1.defibit.io
///
///         Proves the production wiring end-to-end (read-only fork, no funds move):
///           - the known holder of fufufafa22.ai (0x4DaD...952B, balanceOf == 1 on the real
///             SPACE ID Agent ID contract) CAN register;
///           - a random wallet with no Agent ID is REJECTED by the same deployed bytecode.
contract ForkGateTest is Test {
    address internal constant REAL_AGENT_ID = 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F;
    address internal constant KNOWN_HOLDER = 0x4DaD8d9bA451f89E232ade37ac9947D223e0952B; // fufufafa22.ai
    address internal constant NON_HOLDER = 0x000000000000000000000000000000000000dEaD;

    AgentAttestRegistry internal registry;

    function setUp() public {
        registry = new AgentAttestRegistry(REAL_AGENT_ID);
    }

    function test_Fork_RealHolderCanRegister() public {
        assertTrue(registry.isAgentIDHolder(KNOWN_HOLDER));

        vm.prank(KNOWN_HOLDER);
        registry.register("fufufafa22.ai", "free-mint-hunting,quoting", bytes32(0));

        assertTrue(registry.isRegistered(KNOWN_HOLDER));
        assertEq(registry.uniqueInteractors(), 1);
    }

    function test_Fork_NonHolderRejected() public {
        assertFalse(registry.isAgentIDHolder(NON_HOLDER));

        vm.prank(NON_HOLDER);
        vm.expectRevert(
            abi.encodeWithSelector(AgentAttestRegistry.NotAgentIDHolder.selector, NON_HOLDER)
        );
        registry.register("impostor.ai", "spam", bytes32(0));
    }
}
