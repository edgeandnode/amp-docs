---
title: Quickstart Ampup
description: Query smart contracts with SQL
slug: quickstart/querysmartcontracts
category: quickstart
---

Amp automatically transforms your smart contract events into SQL-queryable datasets the moment those events are emitted. There’s no backend to deploy, no indexing code to maintain, and no configuration overhead. Deploy your contract, trigger events, and query the resulting tables immediately using standard SQL. This lets you build real-time dashboards, analytics pipelines, and data-driven applications with the tooling and workflows you already use.

Perfect for prototypes, and production applications that need fast access to on-chain data

This quickstart template walks you from install to your first on-chain SQL query in minutes. You can:

- Query blockchain data using SQL (both from the CLI and in your app)
- Create custom datasets by combining and transforming on-chain data
- Build a React app that displays live blockchain data

> To understand the specifics, see (Ampup Basics)[]/

## 1. Install Prerequisites

Make sure Docker is running. Then install:

### Node and Pnpm

- Node.js (v22+)
- Pnpm (v10+)

> Verify with

```bash
node --version
pnpm --version
```

Older versions may cause issues.

### Foundry

For smart constract development

```bash
curl -L https://foundry.paradigm.xyz | bash && foundryup
```

### Just (as task runner)

```bash
cargo install just
```

### Amp

```bash
curl --proto '=https' --tlsv1.2 -sSf https://ampup.sh/install | sh
```

## 2. Quickstart

### 1. Close Started Template

```bash
# Clone with submodules
git clone --recursive <repository-url>
cd amp-demo
```

### 2. Install project dependencies

```bash
just install
```

### 3. Start Your Local Stack

### Start infrastructure and deploy contracts

```bash
just up
```

### 4. Start Development serves (frontend + Amp)

```bash
just dev
```

- Open: http://localhost:5173
- Click the counter buttons to generate transactions.

## 4. Run Your First SQL Query

In a new terminal, query your dataset:

```bash
# See the events your contract emitted
pnpm amp query 'SELECT * FROM "_/counter@dev".incremented LIMIT 5'
```

Amp automatically created a `incremented` SQL table from your smart contract’s `Incremented` event. No indexing code required.

## 5. Create Your First Derived Table (Optional)

> To understand specifics to datasets, see (Ampup Basics)[]

Raw tables (example: `anvil.blocks`) contain the chain data and are populated for you; with them you can create and deploy derived datasets that pre-compute transformations for faster queries (like a materialized view).

### Example: Filtering Blocks

Edit `amp.config.ts` to add a custom table:

```typescript
import { defineDataset, eventTables } from "@edgeandnode/amp";
// @ts-ignore
import { abi } from "./app/src/lib/abi.ts";

export default defineDataset(() => {
  const baseTables = eventTables(abi);

  return {
    namespace: "eth_global",
    name: "counter",
    network: "anvil",
    description: "Counter dataset with event tables and custom queries",
    dependencies: {
      anvil: "_/anvil@0.0.1", // Access to blocks, transactions, logs
    },
    tables: {
      ...baseTables, // Your contract's event tables

      // Add a custom derived table
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

Amp automatically detects changes to `amp.config.ts` and generates your new `active_blocks` table.

#### Query your new table:

```bash
pnpm amp query 'SELECT * FROM "_/counter@dev".active_blocks LIMIT 10'
```

#### Filtering for a specific contract:

```bash
pnpm amp query 'SELECT * FROM anvil.logs WHERE address = 0xYOUR_CONTRACT_ADDRESS LIMIT 10'
```

## 6. Query Amp from Your App

The frontend (`app/src`) shows how to query Amp datasets from TypeScript. See [`app/src/components/IncrementTable.tsx`](app/src/components/IncrementTable.tsx) for a complete example.

## 7. Hosted Environment

Amp easily transitions from local development to developing on datasets located in a hosted environment.

- Follow the (hosted environment)[guide] to transition Amp from local datasets to published datasets hosted by Edge & Node.

### Interactive Development

Prototype with Amp Studio:

```bash
just studio
```

### Watch Service logs

```bash
just logs
```

### Query from CLI

```bash
pnpm amp query 'SELECT * FROM "_/counter@dev".decremented LIMIT 10'
```

## Conclusion

You’re now ready to build dashboards, analytics tools, agent workflows, or data-driven apps—powered by SQL on on-chain events.

## Notes

### Supported Chains

Local

- **Foundry Anvil** (local development)

On hosted instance (https://playground.amp.thegraph.com/)

- **Ethereum** mainnet
- **Arbitrum** mainnet
- **Base** mainnet
- **Base** Sepolia
