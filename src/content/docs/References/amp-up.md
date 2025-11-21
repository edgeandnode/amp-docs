---
title: Amp Up
description: Overview of Amp Up Core Concepts
slug: /references/ampup/concepts
category: reference
---

This page provides factual definitions, syntax, configuration fields, commands, and dataset behaviors for Amp. Use it when you need precise detail about how Amp works or how to configure datasets.

## 1. Core Concepts

### Event Tables

Amp automatically converts Solidity events into SQL tables using:

```ts
eventTables(abi);
```

- Each event becomes one table.
- Column names derive from the event fields.
- These tables are regenerated on every build.
- No code is needed.

### Datasets

A dataset is a collection of SQL tables derived from:

- Contract events
- Chain-level data (blocks, transactions, logs)
- Custom SQL-defined derived tables

Dataset identifier format:

`"namespace/name@version"`

#### Examples:

- `"\_/counter@dev"` — local development dataset
- `"\_/anvil@0.0.1"` — chain dataset with blocks, transactions, logs
- `@dev` — local development version
- `@latest or @1.0.0` — published versions

Local development namespace: `_/`.

## 2. Dataset Configuration (amp.config.ts)

### Schema

```ts
   export default defineDataset(() => ({
   name: string,
   network: string,
   description?: string,
   dependencies?: Record<string, string>,
   tables: Record<string, TableDefinition>,
   }));
```

### Dependencies

Allows referencing other datasets inside SQL.

```ts
dependencies: {
  anvil: "\_/anvil@0.0.1";
}
```

Provides access to:

- `anvil.blocks`
- `anvil.logs`

### Event Tables

```ts
const baseTables = eventTables(abi);
```

Generates one SQL table per Solidity event.

### Derived Tables

```ts
tables: {
  derived_table_name: {
    sql: `SQL QUERY`;
  }
}
```

Derived table rules (streaming SQL model):

- Unsupported: `GROUP BY`, `LIMIT`, `ORDER BY` inside table definitions
- Supported: `JOIN`, `FILTER`, and transform data from dependencies

#### Example:

```ts
active_blocks: {
  sql: `     SELECT
      block_num,
      hash AS block_hash,
      timestamp,
      gas_used
    FROM anvil.blocks
    WHERE gas_used > 0
  `;
}
```

## 3. CLI Commands

### Query a Dataset

```bash
   pnpm amp query '<SQL>'
```

**Example**:

```bash
pnpm amp query 'SELECT \* FROM "\_/counter@dev".incremented LIMIT 10'
```

### Start Local Services

These commands come from the project’s `justfile`:

```bash
just up # Start infra + Amp + contract deployment
just down # Stop services
just dev # Start frontend + Amp dev services
just logs # Stream logs
just studio # Open Amp Studio for interactive SQL queries
```

## 4. SQL Tables Provided by the Template

### Event Tables

Automatically generated from `Counter.sol`:

- `incremented`
- `decremented`

Chain Tables via Dependency `(_/anvil@0.0.1)`

- `anvil.blocks`
- `anvil.transactions`
- `anvil.logs`

## 5. Client Libraries

**TypeScript / JavaScript**
Package: `@edgeandnode/amp`

Usage example:

```ts
import { useQuery } from "@edgeandnode/amp";

const { data } = useQuery(`  SELECT * FROM "_/counter@dev".incremented
  ORDER BY block_num DESC
  LIMIT 10`);
```

**Rust / Python**
Available via Amp CLI integration.

> All clients use the same SQL query language and connect to the same Amp server.

## 6. Supported Chains

### Local

- Foundry Anvil

### Hosted playground

- Ethereum mainnet
- Arbitrum mainnet
- Base mainnet
- Base Sepolia

> Additional networks are planned.

## 7. Project Structure

```
amp-demo/
├── amp.config.ts                    # Dataset configuration (your SQL tables)
├── amp.config.extended-example.ts   # Extended example with more patterns
├── contracts/src/Counter.sol        # Smart contract with events
├── app/                             # React frontend
│   └── src/components/              # Components that query Amp datasets
├── infra/
│   ├── amp/
│   │   ├── providers/               # Network connection configs
│   │   ├── data/                    # Runtime data (generated)
│   │   └── datasets/                # Build artifacts (generated)
│   └── docker-compose.yaml          # Infrastructure services
└── justfile                         # Task runner commands
```

## 8. Common Questions (Reference Answers)

1. Do I need indexing code?
   No. Amp infers tables automatically from your ABI via `eventTables(abi)`.

2. What are raw tables?
   Tables created directly from events.

3. What are derived tables?
   Tables defined in amp.config.ts using SQL.

4. Why use `@dev`?
   Local datasets use the @dev tag; published datasets use version numbers.

5. Does Amp work with Hardhat?
   Yes. Amp works with any local Ethereum development environment.
