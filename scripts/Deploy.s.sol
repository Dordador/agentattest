// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {AgentAttestRegistry} from "../contracts/AgentAttestRegistry.sol";

/// @notice Deployment script.
///         Local (gas measurement):  forge script scripts/Deploy.s.sol --rpc-url http://127.0.0.1:8545 --broadcast
///         BNB Chain mainnet (ONLY after the user approves the top-up + deploy):
///             forge script scripts/Deploy.s.sol --rpc-url https://bsc-dataseed.binance.org --broadcast --verify ...
///         The Agent ID contract address defaults to the real mainnet SPACE ID Agent ID contract;
///         override with env AGENT_ID_CONTRACT for testnet (where a MockAgentID must be deployed first).
contract Deploy is Script {
    address internal constant MAINNET_AGENT_ID = 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F;

    function run() external returns (AgentAttestRegistry registry) {
        address agentID = vm.envOr("AGENT_ID_CONTRACT", MAINNET_AGENT_ID);
        vm.startBroadcast();
        registry = new AgentAttestRegistry(agentID);
        vm.stopBroadcast();
    }
}
