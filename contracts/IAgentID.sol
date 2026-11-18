// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Minimal interface for the official Binance "Agent ID" NFT on BNB Chain.
/// @dev The real contract is "SPACE ID Agent ID" (symbol "AI"), an ERC-721 soulbound NFT
///      deployed on BNB Chain mainnet at 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F
///      (deployment block 127,950,748, verified on-chain 2026-11-18).
///      Each Agentic Wallet can hold at most one Agent ID, it is non-transferable,
///      and token ids are name-derived (ownerOf of small integers reverts), so
///      `balanceOf(address) > 0` is the correct and sufficient ownership check.
interface IAgentID {
    function balanceOf(address owner) external view returns (uint256);
}
