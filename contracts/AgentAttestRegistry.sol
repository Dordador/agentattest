// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IAgentID} from "./IAgentID.sol";

/// @title AgentAttestRegistry — an Agent-ID-gated attestation & capability registry for AI agents.
/// @notice Agent ID tells the world WHO an agent is. This registry records WHAT an agent can do
///         and WHO vouches for it — entirely on-chain, and only for wallets that hold an Agent ID.
///
///         - `register`  : an Agent ID holder publishes its profile (name, capability tags, endpoint hash).
///         - `attest`    : a registered agent endorses another registered agent for a capability tag.
///
///         Every state-changing call is gated by an on-chain check against the official Agent ID
///         NFT contract (SPACE ID Agent ID, 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F on BNB Chain).
///         Because only Agent ID holders can ever write, `uniqueInteractors` is exactly the number
///         of distinct Agent ID addresses that have interacted with this contract.
///
/// @dev Deliberately dependency-free (no imports beyond the local interface) so the verified
///      source on BscScan is short and auditable. No admin keys, no upgradeability, no fees,
///      no token. The Agent ID contract address is immutable after deployment.
contract AgentAttestRegistry {
    // ---------------------------------------------------------------- errors
    error NotAgentIDHolder(address caller);
    error EmptyName();
    error NameTooLong();
    error CapabilitiesTooLong();
    error NotRegistered(address agent);
    error SelfAttestation();
    error DuplicateAttestation(address from, address to, bytes32 tag);
    error ZeroAddress();

    // ---------------------------------------------------------------- events
    event AgentRegistered(address indexed agent, string name);
    event AgentProfileUpdated(address indexed agent, string name);
    event Attested(address indexed from, address indexed to, bytes32 indexed tag);

    // ---------------------------------------------------------------- types
    struct Profile {
        string name; // display name, e.g. "fufufafa22.ai"
        string capabilities; // comma-separated capability tags, e.g. "free-mint-hunting,quoting,defi"
        bytes32 endpointHash; // keccak256 of the agent's service endpoint / agent card URL
        uint64 registeredAt; // first registration time
        uint64 updatedAt; // last profile update time
        uint32 attestationsReceived; // number of attestations this agent has received
        bool exists;
    }

    struct Attestation {
        address from;
        address to;
        bytes32 tag; // capability tag being endorsed, e.g. keccak256("quoting")
        uint64 timestamp;
    }

    // ---------------------------------------------------------------- state
    /// @notice The official Agent ID NFT contract this registry gates on (immutable).
    IAgentID public immutable agentID;

    mapping(address => Profile) private _profiles;
    address[] private _agents;

    Attestation[] private _attestations;
    mapping(bytes32 => bool) private _attested; // keccak256(from, to, tag) => done

    /// @notice True once an address has made any gated call (register or attest).
    mapping(address => bool) public hasInteracted;
    /// @notice Distinct Agent ID addresses that have interacted — the ecosystem metric.
    uint256 public uniqueInteractors;
    /// @notice Total attestations ever recorded.
    uint256 public totalAttestations;

    uint256 public constant MAX_NAME_LENGTH = 64;
    uint256 public constant MAX_CAPABILITIES_LENGTH = 280;

    // ---------------------------------------------------------------- init
    constructor(address agentIDContract) {
        if (agentIDContract == address(0)) revert ZeroAddress();
        agentID = IAgentID(agentIDContract);
    }

    // ---------------------------------------------------------------- gate
    modifier onlyAgentID() {
        if (agentID.balanceOf(msg.sender) == 0) revert NotAgentIDHolder(msg.sender);
        _;
    }

    function _markInteracted(address who) internal {
        if (!hasInteracted[who]) {
            hasInteracted[who] = true;
            uniqueInteractors += 1;
        }
    }

    // ---------------------------------------------------------------- writes
    /// @notice Register your agent profile, or update it if you are already registered.
    /// @param name Your agent's display name (1–64 bytes), e.g. your .ai Agent ID name.
    /// @param capabilities Comma-separated capability tags (max 280 bytes).
    /// @param endpointHash keccak256 hash of your endpoint URL / agent card (0x0 if none).
    function register(string calldata name, string calldata capabilities, bytes32 endpointHash)
        external
        onlyAgentID
    {
        uint256 nameLen = bytes(name).length;
        if (nameLen == 0) revert EmptyName();
        if (nameLen > MAX_NAME_LENGTH) revert NameTooLong();
        if (bytes(capabilities).length > MAX_CAPABILITIES_LENGTH) revert CapabilitiesTooLong();

        Profile storage p = _profiles[msg.sender];
        bool isNew = !p.exists;
        if (isNew) {
            p.exists = true;
            p.registeredAt = uint64(block.timestamp);
            _agents.push(msg.sender);
        }
        p.name = name;
        p.capabilities = capabilities;
        p.endpointHash = endpointHash;
        p.updatedAt = uint64(block.timestamp);

        _markInteracted(msg.sender);
        if (isNew) emit AgentRegistered(msg.sender, name);
        else emit AgentProfileUpdated(msg.sender, name);
    }

    /// @notice Endorse another registered agent for a capability tag.
    /// @param target The registered agent you are vouching for.
    /// @param tag Capability tag, e.g. keccak256("free-mint-hunting"). One attestation per (you, target, tag).
    function attest(address target, bytes32 tag) external onlyAgentID {
        if (target == address(0)) revert ZeroAddress();
        if (target == msg.sender) revert SelfAttestation();
        if (!_profiles[msg.sender].exists) revert NotRegistered(msg.sender);
        if (!_profiles[target].exists) revert NotRegistered(target);

        bytes32 key = keccak256(abi.encode(msg.sender, target, tag));
        if (_attested[key]) revert DuplicateAttestation(msg.sender, target, tag);
        _attested[key] = true;

        _attestations.push(
            Attestation({from: msg.sender, to: target, tag: tag, timestamp: uint64(block.timestamp)})
        );
        _profiles[target].attestationsReceived += 1;
        totalAttestations += 1;

        _markInteracted(msg.sender);
        emit Attested(msg.sender, target, tag);
    }

    // ---------------------------------------------------------------- views
    /// @notice True if `who` currently holds an Agent ID (the gate check, exposed for convenience).
    function isAgentIDHolder(address who) external view returns (bool) {
        return agentID.balanceOf(who) > 0;
    }

    /// @notice True if `who` has a registered profile.
    function isRegistered(address who) external view returns (bool) {
        return _profiles[who].exists;
    }

    /// @notice Number of registered agent profiles.
    function totalAgents() external view returns (uint256) {
        return _agents.length;
    }

    /// @notice Full profile of one agent. Reverts if the agent is not registered.
    function getProfile(address who)
        external
        view
        returns (
            string memory name,
            string memory capabilities,
            bytes32 endpointHash,
            uint64 registeredAt,
            uint64 updatedAt,
            uint32 attestationsReceived
        )
    {
        Profile storage p = _profiles[who];
        if (!p.exists) revert NotRegistered(who);
        return (p.name, p.capabilities, p.endpointHash, p.registeredAt, p.updatedAt, p.attestationsReceived);
    }

    /// @notice Paginated list of registered agent addresses (for dashboards / indexers).
    function getAgents(uint256 offset, uint256 limit) external view returns (address[] memory page) {
        uint256 total = _agents.length;
        if (offset >= total) return new address[](0);
        uint256 end = offset + limit;
        if (end > total) end = total;
        page = new address[](end - offset);
        for (uint256 i = offset; i < end; i++) {
            page[i - offset] = _agents[i];
        }
    }

    /// @notice One attestation record by index (0 .. totalAttestations-1).
    function getAttestation(uint256 index)
        external
        view
        returns (address from, address to, bytes32 tag, uint64 timestamp)
    {
        Attestation storage a = _attestations[index];
        return (a.from, a.to, a.tag, a.timestamp);
    }

    /// @notice True if `from` has already attested `to` for `tag`.
    function hasAttested(address from, address to, bytes32 tag) external view returns (bool) {
        return _attested[keccak256(abi.encode(from, to, tag))];
    }
}
