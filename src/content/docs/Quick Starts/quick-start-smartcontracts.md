---
title: Quickstart Ampup
description: Query smart contracts with SQL
slug: quickstart/querysmartcontracts
category: quickstart
---

Query your smart contracts with SQL. No backend, no indexers, no setup code.

Amp turns Solidity events into SQL tables instantly. Deploy, emit events, and query them right away. Perfect for rapid prototyping, dashboards, analytics, and AI agents.

> This guide uses the TypeScript SDK.

## 1. Install Prerequisites

Make sure you have Docker running. Then install:

### Node and Pnpm

- Node.js (v22+)
- Pnpm (v10+)

> Verify with node `--version` and pnpm `--version`. Older versions may cause issues.

# Foundry

```bash
curl -L https://foundry.paradigm.xyz | bash && foundryup
```

# Just (task runner)

```bash
cargo install just
```

# Amp CLI

```bash
curl --proto '=https' --tlsv1.2 -sSf https://ampup.sh/install | sh
```

## 2. Clone the Starter Template

```bash
git clone --recursive <repository-url>
cd amp-demo
```

### Install project dependencies (frontend, SDK, etc.)

```bash
just install
```

## 3. Start Your Local Stack

### Start infra and deploy contracts

```bash
just up
```

### In another terminal: start development servers (frontend + Amp)

```bash
just dev
```

Open: http://localhost:5173
Click the counter buttons to emit `Incremented` / `Decremented` events from the `Counter` contract.

## 4. Run Your First SQL Query

In a new terminal (from the `amp-demo` directory):

```bash
pnpm amp query 'SELECT * FROM "_/counter@dev".incremented LIMIT 5'
```

Datasets use the format `namespace/name@version`

- `"_/counter@dev"` is your local dataset.
- `@dev` for local development, @latest or @1.0.0 for published datasets
- `_/` is your personal namespace for local development.
- `incremented` is the table Amp auto-generated from the `Incremented` event in `Counter.sol`.

Amp auto-created the incremented table from your contract. No indexing code required.

## 5. Add a Custom Derived Table

You can define your own tables on top of chain data (like a materialized view).

Open `amp.config.ts` and replace its contents with this technically complete config:

```typescript
import { defineDataset, eventTables } from "@edgeandnode/amp";
// @ts-ignore
import { abi } from "./app/src/lib/abi.ts";

export default defineDataset(() => {
  const baseTables = eventTables(abi);

  return {
    name: "counter",
    network: "anvil",
    description: "Counter dataset with event tables and custom queries",
    // Gives access to chain-level data like blocks, txs, logs
    dependencies: {
      anvil: "_/anvil@0.0.1",
    },
    tables: {
      // Auto-generated tables for your contract events
      ...baseTables,

      // Custom derived table: only blocks with gas usage > 0
      active_blocks: {
        sql: `
          SELECT
            block_num,
            hash AS block_hash,
            timestamp,
            gas_used
          FROM anvil.blocks
          WHERE gas_used > 0
        `,
      },
    },
  };
});
```

Deploy your changes:

```bash
just down
just up
```

Now, query your new table:

```bash
pnpm amp query 'SELECT * FROM "_/counter@dev".active_blocks LIMIT 10'
```

## 6. Query Amp from Your App

The frontend (`app/src`) shows how to query Amp datasets from TypeScript using the `@edgeandnode/amp` client library.

Example from `app/src/components/IncrementedEvents.tsx`:

```tsx
import { useQuery } from "@edgeandnode/amp";

const { data } = useQuery(`
  SELECT * FROM "_/counter@dev".incremented
  ORDER BY block_num DESC
  LIMIT 10
`);
```

> Assumes the `incremented` table has columns like `block_num`, `tx_hash`, `log_index`, `new_value` generated from your event fields.

## 7. Explore & Debug Quickly

### Open Amp Studio for web-based queries

```bash
just studio
```

### Watch Service logs

```bash
just logs
```

### Query from CLI

```bash
pnpm amp query 'SELECT * FROM "_/counter@dev".decremented LIMIT 5'
```

## Conclusion

You’re now production-ready:

- Contracts emit events
- Amp turns them into SQL tables
- You can query from CLI, Amp Studio, or TypeScript/React

## Notes

### Supported Chains

Local

- **Foundry Anvil** (local development)

On hosted instance (https://playground.amp.thegraph.com/)

- **Ethereum** mainnet
- **Arbitrum** mainnet
- **Base** mainnet
- **Base** Sepolia
