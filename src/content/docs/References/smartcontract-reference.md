---
title: Smart Contracts with SQL
description: Understanding how Amp works with sql
slug: references/contractsql
category: references
---

## Overview

Amp turns contract events into SQL tables so you can query blockchain data instantly. This reference page documents the core concepts, configuration patterns, supported environments, and common workflows.

### Example Use Cases

- Cross-chain portfolio dashboard that aggregates wallet positions and liquidity using Amp token datasets
- Risk analytics or MEV monitor that visualizes transaction patterns or protocol surface exposure
- NFT trait liquidity explorer that ranks collections by floor depth and trading velocity using Amp NFT datasets

## How Amp Works

Event to Table Pipeline

- Your contracts emit standard events.
- Amp automatically converts those events into SQL tables.
- No indexing logic, no schema management, no backend services required.

## Query Anywhere

Use SQL from:

- TypeScript / JavaScript
- Rust (via CLI)
- Python (via CLI)
- Amp CLI
- Amp Studio (browser)

## Development Environments

Amp integrates seamlessly with:

- Foundry (Anvil)
- Hardhat
- Any local Ethereum dev chain

## Datasets

A dataset is a collection of SQL tables built from onchain data. Think of them as your data warehouse for onchain events.

### Dataset Naming Convention

### Format:

```
namespace/name@version
```

**Examples**:

- `"_/counter@dev"`: your local dataset

- `"_/anvil@0.0.1"`: chain-level data (blocks, txs, logs)

**Conventions**:

- `@dev` for local development
- `@latest` or `@1.0.0` for published datasets
- `_/` is the personal local namespace

The dataset configuration is in `amp.config.ts`. It uses `eventTables(abi)` to automatically generate SQL tables from your contract events.

### Raw Tables

Raw tables contain chain data and are populated automatically by Amp.
**Example**: `anvil.blocks` exposes block-level fields such as block number, hash, timestamp, and gas usage.

Raw tables also include the event tables Amp generates from your contract ABI using `eventTables(abi)`.

These tables form the base layer you can use to build custom, derived datasets.

### Derived Tables

Derived tables allow you to pre-compute filtered or transformed data for faster queries, similar to a materialized view.

Derived tables can pull from any dataset declared in `dependencies`, such as:

- `anvil.blocks`
- `anvil.logs`

#### SQL Limitations (Streaming Model)

Inside a derived table definition:

- No `GROUP` BY
- No `ORDER` BY
- No `LIMIT`

For full details, see docs/streaming.md.

#### Example: Adding a Derived Table

```ts
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
      anvil: "_/anvil@0.0.1",
    },
    tables: {
      ...baseTables,

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

Amp automatically detects changes to amp.config.ts and generates the new active_blocks table.

## Querying Tables

Query the derived table:

```bash
pnpm amp query 'SELECT * FROM "_/counter@dev".active_blocks LIMIT 10'
```

Filter logs for a specific contract:

```bash
pnpm amp query 'SELECT * FROM anvil.logs WHERE address = 0xYOUR_CONTRACT_ADDRESS LIMIT 10'
```

## Project Structure

```bash
amp-demo/
├── amp.config.ts             # Dataset configuration
├── contracts/src/Counter.sol # Contracts with events
├── app/                      # React frontend
│   ├── src/components/       # Components that query Amp datasets
│   └── src/lib/              # Amp client utilities
├── infra/
│   ├── amp/                  # Providers, data, generated artifacts
│   └── docker-compose.yaml   # Local services
└── justfile                  # Task runner commands
```

## Client Libraries

Amp supports multiple languages:

- TypeScript/JavaScript
- Rust (via CLI)
- Python (via CLI)

All clients use the same SQL query engine.

## Supported Chains

### Local

- Foundry Anvil
- Hardhat

### Hosted (https://playground.amp.thegraph.com/)

- Ethereum mainnet
- Arbitrum mainnet
- Base mainnet
- Base Sepolia

Roadmap includes additional major chains.

## Hosted Environment Development

Amp transitions smoothly from local datasets to published datasets hosted by Edge & Node.

See:

- docs/hosted-env.md
- docs/streaming.md
- docs/troubleshooting.md

## Common Questions

1. Do I need indexing code?
   No. Amp auto-generates SQL tables from contract events.

2. Can I use Hardhat?
   Yes. Amp works with any EVM local dev chain.

3. Raw vs Derived tables?
   Raw tables mirror events. Derived tables transform your data using SQL for faster queries.

4. Why `@dev` in queries?
   Local datasets use the `@dev` tag. Published datasets use semantic versions.
