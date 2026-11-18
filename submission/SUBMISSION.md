# Agent ID Hackathon — Project Submission (DRAFT)

> Submission window closes **9 Dec 2026, 08:00 UTC**. Submit via the official Binance
> campaign page (in-app uni-qr link from the hackathon announcement).
> Items marked `{{…}}` are filled in at deployment time.

## Project name
**AgentAttest** — the Agent-ID-gated attestation & capability registry for AI agents on BNB Chain.

## One-liner
Agent ID says *who* an agent is. AgentAttest records *what an agent can do* and *who vouches for it* —
on-chain, and writable only by Agent ID holders themselves.

## Problem
182,000+ Agent IDs were claimed in the first three weeks (BAS index, Nov 2026), yet identity is
only the first rung: as BAS's analysis puts it, "Agent ID tells you who is behind a wallet, not
what the wallet does." Today there is no shared, trustworthy place for an agent to declare its
capabilities or for other agents to endorse them. Anyone hiring an agent on BNB Chain has to
trust off-chain claims.

## Solution
A single, dependency-free smart contract on BNB Chain:

- **`register(name, capabilities, endpointHash)`** — an Agent ID holder publishes its profile:
  display name, capability tags, and a hash of its service endpoint / agent card.
- **`attest(target, tag)`** — a registered agent endorses another registered agent for a
  specific capability. Attestations are stored on-chain (and emitted as events), are
  non-duplicable per (endorser, target, tag), and can never be self-issued.
- **The gate is Agent ID itself.** Every write first checks the official SPACE ID Agent ID
  contract (`0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F`) with `balanceOf(caller) > 0`.
  No Agent ID → the call reverts. This is enforced by the EVM, not by a server.

## Why this fits the Ecosystem Leader award
- **Every interaction is an Agent ID interaction — by construction.** Because the gate is
  checked on-chain for each call, the contract's `uniqueInteractors` counter *is* the count of
  distinct interacting Agent ID addresses; it cannot be inflated by non-holders.
- **Interaction is nearly free:** register ≈ $0.005 and attest ≈ $0.006 in gas at current BSC
  prices, so holders can participate without thinking about cost.
- **Built to spread:** a read-only judge dashboard, a BscScan no-code path, and a copy-paste
  integration kit (cast / ethers / Agentic Wallet) let any of the 182k holders join with one call.

## Why this fits the Application Innovation award
- It adds the **missing rung** above Agent ID: verifiable capability + reputation, without a
  new identity system, a token, or an off-chain oracle.
- **Radically simple trust model:** no admin keys, no upgradeability, no fees, no external
  dependencies — the entire verified source is one short contract a judge can read in minutes.
- Composable by design: any dApp can read `getProfile` / `hasAttested` / `attestationsReceived`
  to gate or rank agents (e.g. "only hire agents with ≥3 attestations for `quoting`").

## How Agent ID is used
- Gate on every state-changing function via the official Agent ID NFT contract (immutable
  reference set at deployment).
- Profiles are keyed by the holder's wallet — the same address that owns the `.ai` name.
- Fork tests against BNB Chain mainnet prove the production wiring: a real Agent ID holder
  (fufufafa22.ai) registers successfully; a non-holder is rejected by the same bytecode.

## Verification & security
- 15 unit tests + 2 mainnet-fork tests, all passing (`forge test`).
- Verified source: https://bscscan.com/address/0x29f924c94b8cbb6c8963cfb23f73b7d399678280#code
  (Sourcify **exact_match** — creation + runtime — matchId 59472454, verified 2026-11-18;
  resolvable at https://sourcify.dev/server/v2/contract/56/0x29f924c94b8cbb6c8963cfb23f73b7d399678280)
- No funds are ever held by the contract; calls carry 0 value.

## Links
- Contract (BNB Chain mainnet): 0x29f924c94b8cbb6c8963cfb23f73b7d399678280
- BscScan: https://bscscan.com/address/0x29f924c94b8cbb6c8963cfb23f73b7d399678280
- Deploy tx (CREATE2 via the canonical deterministic-deployment proxy, from the owner's
  Agentic Wallet): https://bscscan.com/tx/0xe15cdab66f800863b617729d540ebf01d475519c8e5539f26db60f53e80e65af
- First registration (fufufafa22.ai, agent #1):
  https://bscscan.com/tx/0x1e19313a75f71d373153b2e3fd233fec830e45a28fc0f9e328403777143523a4
- Dashboard + join page (live counters, wallet register/attest): https://dordador.github.io/agentattest/
- Source code: https://github.com/Dordador/agentattest
- Demo video: {{VIDEO_LINK}}
- Integration kit: `docs/INTEGRATION-KIT.md` in the repo

## Team
Built by **Tukang becak** (Juventini Nizar) with his AI agent **fufufafa22.ai** — itself a
registered AgentAttest agent (#1), an Agent ID holder active daily in Agent-ID-gated mints,
Agent Cards, and an agent-to-agent task marketplace. The project is dogfooded by its own author.

## Roadmap
1. Deploy + verify on mainnet; seed the first profiles from the Agent ID holder community.
2. Reach 30+ interacting Agent ID addresses before the 9 Dec deadline (live counter on the dashboard).
3. Post-hackathon: public tag vocabulary, richer discovery (search by capability), and
   integrations with agent marketplaces that want a trust signal for hiring.

## Submission checklist
- [x] User approves BNB top-up for deployment gas (0.002018 BNB landed 2026-11-18)
- [x] Deploy to BNB Chain mainnet — DONE 2026-11-18 via the owner's Agentic Wallet (baw):
      CREATE2 through the canonical deterministic-deployment proxy
      (0x4e59b44847b379578588920cA78FbF26c0B4956C, salt 0x…01), because baw `contract-call`
      cannot broadcast a native creation tx. Contract: 0x29f924c94b8cbb6c8963cfb23f73b7d399678280
- [x] Verify source — Sourcify exact_match (creation + runtime), 2026-11-18
- [x] Register fufufafa22.ai as agent #1 (uniqueInteractors = 1, confirmed on-chain)
- [x] Host dashboard + repo publicly — DONE 2026-11-19: dashboard on GitHub Pages
      (https://dordador.github.io/agentattest/, register + attest wallet flows live, counters
      read from chain), repo public at https://github.com/Dordador/agentattest. Video link still pending.
- [ ] Drive to ≥ 30 interacting Agent ID addresses (plan in STATUS.md)
- [ ] Submit the form on the official campaign page before 9 Dec 2026 08:00 UTC
