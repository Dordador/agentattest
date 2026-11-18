// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {AgentAttestRegistry} from "../contracts/AgentAttestRegistry.sol";
import {MockAgentID} from "../contracts/mocks/MockAgentID.sol";

/// @notice Test suite for AgentAttestRegistry.
///         The headline proofs for the hackathon:
///           1. A wallet WITHOUT an Agent ID is REJECTED by the gate (register + attest revert).
///           2. A wallet WITH an Agent ID succeeds, and the interaction is counted.
///         In production the MockAgentID below is swapped for the real SPACE ID Agent ID
///         contract at 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F — the registry only ever
///         calls balanceOf(address), which the mock mirrors exactly.
contract AgentAttestRegistryTest is Test {
    MockAgentID internal agentID;
    AgentAttestRegistry internal registry;

    address internal alice = makeAddr("alice"); // Agent ID holder
    address internal bob = makeAddr("bob"); // Agent ID holder
    address internal carol = makeAddr("carol"); // Agent ID holder, never registers
    address internal mallory = makeAddr("mallory"); // NO Agent ID

    bytes32 internal constant TAG_QUOTING = keccak256("quoting");
    bytes32 internal constant TAG_MINT = keccak256("free-mint-hunting");
    bytes32 internal constant ENDPOINT = keccak256("https://agent.example/card.json");

    function setUp() public {
        agentID = new MockAgentID();
        registry = new AgentAttestRegistry(address(agentID));

        // alice, bob, carol hold an Agent ID; mallory does not.
        vm.prank(alice);
        agentID.claim();
        vm.prank(bob);
        agentID.claim();
        vm.prank(carol);
        agentID.claim();
    }

    // ------------------------------------------------------------ gate: register
    function test_NonHolder_CannotRegister() public {
        vm.prank(mallory);
        vm.expectRevert(
            abi.encodeWithSelector(AgentAttestRegistry.NotAgentIDHolder.selector, mallory)
        );
        registry.register("mallory.ai", "spam", ENDPOINT);

        assertEq(registry.totalAgents(), 0);
        assertEq(registry.uniqueInteractors(), 0);
        assertFalse(registry.isRegistered(mallory));
    }

    function test_Holder_CanRegister() public {
        vm.prank(alice);
        registry.register("fufufafa22.ai", "free-mint-hunting,quoting", ENDPOINT);

        assertTrue(registry.isRegistered(alice));
        assertTrue(registry.isAgentIDHolder(alice));
        assertEq(registry.totalAgents(), 1);
        assertEq(registry.uniqueInteractors(), 1);
        assertTrue(registry.hasInteracted(alice));

        (string memory name, string memory caps, bytes32 ep, , , uint32 received) =
            registry.getProfile(alice);
        assertEq(name, "fufufafa22.ai");
        assertEq(caps, "free-mint-hunting,quoting");
        assertEq(ep, ENDPOINT);
        assertEq(received, 0);
    }

    function test_Register_EmitsEvent() public {
        vm.prank(alice);
        vm.expectEmit(true, false, false, true, address(registry));
        emit AgentAttestRegistry.AgentRegistered(alice, "fufufafa22.ai");
        registry.register("fufufafa22.ai", "quoting", ENDPOINT);
    }

    function test_Register_UpdateDoesNotDoubleCount() public {
        vm.startPrank(alice);
        registry.register("fufufafa22.ai", "quoting", ENDPOINT);
        registry.register("fufufafa22.ai", "quoting,defi-research", ENDPOINT);
        vm.stopPrank();

        assertEq(registry.totalAgents(), 1);
        assertEq(registry.uniqueInteractors(), 1);
        (, string memory caps, , , , ) = registry.getProfile(alice);
        assertEq(caps, "quoting,defi-research");
    }

    function test_Register_Validation() public {
        vm.startPrank(alice);
        vm.expectRevert(AgentAttestRegistry.EmptyName.selector);
        registry.register("", "quoting", ENDPOINT);

        vm.expectRevert(AgentAttestRegistry.NameTooLong.selector);
        registry.register(
            "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", "quoting", ENDPOINT
        );
        vm.stopPrank();
    }

    // ------------------------------------------------------------ gate: attest
    function test_NonHolder_CannotAttest() public {
        vm.prank(alice);
        registry.register("fufufafa22.ai", "quoting", ENDPOINT);

        vm.prank(mallory);
        vm.expectRevert(
            abi.encodeWithSelector(AgentAttestRegistry.NotAgentIDHolder.selector, mallory)
        );
        registry.attest(alice, TAG_QUOTING);

        assertEq(registry.totalAttestations(), 0);
    }

    function test_Holder_CanAttestRegisteredAgent() public {
        vm.prank(alice);
        registry.register("fufufafa22.ai", "quoting", ENDPOINT);
        vm.prank(bob);
        registry.register("bob.ai", "defi-research", ENDPOINT);

        vm.prank(bob);
        registry.attest(alice, TAG_QUOTING);

        assertEq(registry.totalAttestations(), 1);
        assertTrue(registry.hasAttested(bob, alice, TAG_QUOTING));
        (, , , , , uint32 received) = registry.getProfile(alice);
        assertEq(received, 1);

        (address from, address to, bytes32 tag, ) = registry.getAttestation(0);
        assertEq(from, bob);
        assertEq(to, alice);
        assertEq(tag, TAG_QUOTING);
    }

    function test_Attest_RequiresRegisteredSender() public {
        vm.prank(alice);
        registry.register("fufufafa22.ai", "quoting", ENDPOINT);

        // carol holds an Agent ID but never registered a profile.
        vm.prank(carol);
        vm.expectRevert(abi.encodeWithSelector(AgentAttestRegistry.NotRegistered.selector, carol));
        registry.attest(alice, TAG_QUOTING);
    }

    function test_Attest_RequiresRegisteredTarget() public {
        vm.prank(alice);
        registry.register("fufufafa22.ai", "quoting", ENDPOINT);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(AgentAttestRegistry.NotRegistered.selector, bob));
        registry.attest(bob, TAG_QUOTING);
    }

    function test_Attest_NoSelfAttestation() public {
        vm.prank(alice);
        registry.register("fufufafa22.ai", "quoting", ENDPOINT);

        vm.prank(alice);
        vm.expectRevert(AgentAttestRegistry.SelfAttestation.selector);
        registry.attest(alice, TAG_QUOTING);
    }

    function test_Attest_NoDuplicates_ButDifferentTagOk() public {
        vm.prank(alice);
        registry.register("fufufafa22.ai", "quoting", ENDPOINT);
        vm.prank(bob);
        registry.register("bob.ai", "defi-research", ENDPOINT);

        vm.startPrank(bob);
        registry.attest(alice, TAG_QUOTING);
        vm.expectRevert(
            abi.encodeWithSelector(
                AgentAttestRegistry.DuplicateAttestation.selector, bob, alice, TAG_QUOTING
            )
        );
        registry.attest(alice, TAG_QUOTING);
        // A different tag from the same pair is a new, valid attestation.
        registry.attest(alice, TAG_MINT);
        vm.stopPrank();

        assertEq(registry.totalAttestations(), 2);
    }

    // ------------------------------------------------------------ ecosystem metric
    function test_UniqueInteractors_CountsDistinctAgentIDAddresses() public {
        vm.prank(alice);
        registry.register("fufufafa22.ai", "quoting", ENDPOINT);
        vm.prank(bob);
        registry.register("bob.ai", "defi-research", ENDPOINT);
        vm.prank(bob);
        registry.attest(alice, TAG_QUOTING);
        // Re-registering / attesting again must not inflate the count.
        vm.prank(alice);
        registry.register("fufufafa22.ai", "quoting,v2", ENDPOINT);

        assertEq(registry.uniqueInteractors(), 2);
        assertEq(registry.totalAgents(), 2);
        assertEq(registry.totalAttestations(), 1);
    }

    function test_GetAgents_Pagination() public {
        vm.prank(alice);
        registry.register("fufufafa22.ai", "quoting", ENDPOINT);
        vm.prank(bob);
        registry.register("bob.ai", "defi-research", ENDPOINT);

        address[] memory page = registry.getAgents(0, 10);
        assertEq(page.length, 2);
        assertEq(page[0], alice);
        assertEq(page[1], bob);

        address[] memory empty = registry.getAgents(5, 10);
        assertEq(empty.length, 0);
    }

    // ------------------------------------------------------------ misc
    function test_Constructor_ZeroAddressReverts() public {
        vm.expectRevert(AgentAttestRegistry.ZeroAddress.selector);
        new AgentAttestRegistry(address(0));
    }

    function test_GateFollowsLiveOwnership() public {
        // If an address loses its Agent ID balance, the gate closes for it.
        agentID.setBalance(alice, 0);
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(AgentAttestRegistry.NotAgentIDHolder.selector, alice)
        );
        registry.register("fufufafa22.ai", "quoting", ENDPOINT);
    }
}
