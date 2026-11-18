# AgentAttest

**An Agent-ID-gated attestation & capability registry for AI agents on BNB Chain.**
Built for the Binance Wallet × BNB Chain **Agent ID Hackathon** (project track).

Agent ID says *who* an agent is. AgentAttest records *what an agent can do* and *who vouches
for it* — on-chain, and writable **only** by wallets that hold an official Agent ID
(SPACE ID Agent ID NFT, `0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F`). Every write checks
`balanceOf(caller) > 0` against that contract; non-holders are rejected by the EVM itself.

## Live

| | |
|---|---|
| **Join / dashboard** | **https://dordador.github.io/agentattest/** — connect a wallet on BNB Chain and register with one call (≈ $0.005 gas) |
| Contract (BNB Chain mainnet) | `0x29f924c94b8cbb6c8963cfb23f73b7d399678280` |
| BscScan | https://bscscan.com/address/0x29f924c94b8cbb6c8963cfb23f73b7d399678280 |
| Source verification | Sourcify **exact_match** (creation + runtime), matchId 59472454 |
| Deploy tx | https://bscscan.com/tx/0xe15cdab66f800863b617729d540ebf01d475519c8e5539f26db60f53e80e65af |

Because only Agent ID holders can ever write, the contract's `uniqueInteractors` counter *is*
the number of distinct Agent ID addresses that have interacted — it cannot be inflated by
non-holders. No admin keys, no upgradeability, no fees, no token, no funds held.

## What's here

| Path | What |
|---|---|
| `contracts/AgentAttestRegistry.sol` | The registry — one dependency-free contract (register + attest + views) |
| `contracts/IAgentID.sol` | Minimal interface for the official Agent ID NFT |
| `contracts/mocks/MockAgentID.sol` | Test double mirroring the real contract's `balanceOf` |
| `test/AgentAttestRegistry.t.sol` | 15 unit tests — non-holder rejected, holder succeeds, metric counting |
| `test/ForkGate.t.sol` | 2 mainnet-fork tests against the **real** Agent ID contract |
| `scripts/Deploy.s.sol` | Deployment script |
| `docs/index.html` | The live dashboard + join page (GitHub Pages) — live counters, agent table, lookup, event trail, wallet register/attest |
| `dashboard/index.html` | Same page, kept at the original path |
| `docs/INTEGRATION-KIT.md` | How any Agent ID holder interacts in a few lines (cast / ethers / baw / BscScan) |
| `submission/SUBMISSION.md` | The hackathon submission package |

## Run the tests

```bash
forge build
forge test                                   # 15 unit tests
forge test --match-contract ForkGateTest \
  --fork-url https://bsc-dataseed1.defibit.io   # 2 fork tests vs the real Agent ID contract
```

## Measured gas (local EVM, identical rules to BNB Chain)

| Action | Gas | Cost (USD) |
|---|---|---|
| Deploy registry | 1,066,441 | ≈ $0.03 |
| `register` | 155k–255k | ≈ $0.005 |
| `attest` | ≈ 196k | ≈ $0.006 |
