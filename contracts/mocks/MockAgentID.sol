// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Test double for the official Agent ID NFT contract.
/// @dev Mirrors the one property the registry relies on: balanceOf(address).
///      In production the registry points at the real SPACE ID Agent ID contract
///      (0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F), where each Agentic Wallet
///      holds either 0 or 1 soulbound Agent ID.
contract MockAgentID {
    mapping(address => uint256) private _balances;

    string public constant name = "SPACE ID Agent ID (Mock)";
    string public constant symbol = "AI";

    /// @notice Simulate claiming an Agent ID (sets balance to 1, like the real soulbound mint).
    function claim() external {
        _balances[msg.sender] = 1;
    }

    /// @notice Test helper: set an arbitrary balance for any address.
    function setBalance(address who, uint256 amount) external {
        _balances[who] = amount;
    }

    function balanceOf(address who) external view returns (uint256) {
        return _balances[who];
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == 0x80ac58cd || interfaceId == 0x01ffc9a7 || interfaceId == 0x5b5e139f;
    }
}
