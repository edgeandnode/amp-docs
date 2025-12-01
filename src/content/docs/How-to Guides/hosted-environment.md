---
title: Hosted Environment
slug: how-to/hostedenvironment
category: how-to-guide
---

This guide explains how to use Amp’s hosted service maintained by [Edge & Node](https://www.edgeandnode.com/). It provides actionable steps for querying published datasets, migrating from local to hosted development, and publishing your own dataset.

## Overview

[Edge & Node](https://www.edgeandnode.com/) maintains real-time indexed blockchain datasets containing blocks, transactions, and logs. These datasets are queryable with SQL.

### Benefits

- **No infrastructure**: Skip node management, indexing, and database setup.
- **Instant queries**: Access blockchain data with SQL immediately.
- **Production ready**: Build applications on reliable, continuously updated datasets.
- **Composable**: Combine multiple published datasets in a single query.

### Supported Networks

- `ethereum-mainnet`
- `arbitrum-one`
- `base-mainnet`
- `base-sepolia`

More networks are planned.

### Entry Points

1. Query existing datasets
2. Transition from local to hosted
3. Publish your dataset

## Query Existing Datasets

Use published blockchain datasets without running local infrastructure.

### Step 1: Test Queries

Visit the Amp Playground to validate data availability:
<https://playground.amp.thegraph.com>

### Step 2: Generate an Auth Token

```bash
pnpm amp auth token "3 days"
```

Save the token for CLI queries or environment variables.

### Step 3: Run Queries

#### CLI Query Example

```bash
pnpm amp query \
  --flight-url https://gateway.amp.staging.thegraph.com \
  --bearer-token YOUR_TOKEN_HERE \
  'SELECT block_num, hash FROM "edgeandnode/ethereum_mainnet@0.0.1".blocks ORDER BY block_num DESC LIMIT 5'
```

#### Filter Logs by Contract

```bash
pnpm amp query \
  --flight-url https://gateway.amp.staging.thegraph.com \
  --bearer-token YOUR_TOKEN_HERE \
  'SELECT block_num, tx_hash FROM "edgeandnode/ethereum_mainnet@0.0.1".logs WHERE address = 0xYOUR_CONTRACT_ADDRESS LIMIT 10'
```

#### Use From an Application

Add credentials:

```bash
VITE_AMP_QUERY_URL=https://gateway.amp.staging.thegraph.com
VITE_AMP_QUERY_TOKEN=amp_your_token_here
```

Example client usage:

```bash
import { ArrowFlight } from "@edgeandnode/amp";
import { Effect, Stream } from "effect";

const query = Effect.gen(function* () {
  const arrow = yield* ArrowFlight.ArrowFlight;

  const sql = `
    SELECT block_num, hash, gas_used
    FROM "edgeandnode/ethereum_mainnet@0.0.1".blocks
    WHERE gas_used > 0
    ORDER BY block_num DESC
    LIMIT 100
  `;

  return yield* arrow.query([sql] as any).pipe(Stream.runCollect);
});
```

## Transition from Local to Hosted

Migrate your local dataset to a hosted network.

### Prerequisites

- Contract deployed to the target network
- ABI matches the deployed contract


### Step 1: Configure Environment

```bash
cp .env.example .env

````

Enable the target network:
```bash
VITE_AMP_RPC_DATASET=edgeandnode/ethereum_mainnet@0.0.1
VITE_AMP_NETWORK=ethereum-mainnet
```

### Step 2: Update Dataset Config

```typescript
import { defineDataset, eventTables } from "@edgeandnode/amp";
// @ts-ignore
import { abi } from "./app/src/lib/abi.ts";

export default defineDataset(() => ({
  name: "counter",
  network: "ethereum-mainnet",
  dependencies: {
    rpc: "edgeandnode/ethereum_mainnet@0.0.1",
  },
  tables: eventTables(abi, "rpc"),
}));
```

### Step 3: Test Configuration

Validate Build

```bash
pnpm amp build -o /tmp/test-manifest.json
```

Generate Token

```bash
pnpm amp auth token "3 days"
```

Verify Connectivity

```bash
pnpm amp query \
  --flight-url https://gateway.amp.staging.thegraph.com \
  --bearer-token YOUR_TOKEN_HERE \
  'SELECT block_num, hash FROM "edgeandnode/ethereum_mainnet@0.0.1".blocks ORDER BY block_num DESC LIMIT 5'
```

Verify Contract Events

```bash
pnpm amp query \
  --flight-url https://gateway.amp.staging.thegraph.com \
  --bearer-token YOUR_TOKEN_HERE \
  'SELECT block_num, tx_hash FROM "edgeandnode/ethereum_mainnet@0.0.1".logs WHERE address = 0xYOUR_CONTRACT_ADDRESS LIMIT 10'
```

If results appear, your configuration is correct.

### Step 4: Run the App

```bash
just dev
```

## Publish Your Dataset (Optional)

Publish your dataset to the Amp registry for public querying.

### Prerequisites

- Queries return expected data
- Contract deployed
- Dataset defined in amp.config.ts

### Step 1: Add Publishing Metadata

Add recommended metadata to `amp.config.ts` for discoverability:

```typescript
import { defineDataset, eventTables } from "@edgeandnode/amp";
// @ts-ignore
import { abi } from "./app/src/lib/abi.ts";

export default defineDataset(() => ({
  name: "counter",
  network: "ethereum-mainnet",
  dependencies: {
    rpc: "edgeandnode/ethereum_mainnet@0.0.1",
  },
  tables: eventTables(abi, "rpc"),

  namespace: "your_namespace",
  description: "Counter dataset tracking increment/decrement events",
  keywords: ["Ethereum", "Counter", "Events"],
}));
```

### Step 2: Authenticate

```bash
pnpm amp auth login
```

This opens a browser for wallet or social authentication.

### Step 3: Publish

```bash
pnpm amp publish --tag "0.0.1" --changelog "Initial release"
```

- `--tag` (REQUIRED) - Semantic version: `{major}.{minor}.{patch}`
- `--changelog` (optional) - Describe changes in this version

Dataset URL:

`your_namespace/counter@0.0.1`

### Step 4: Generate Auth Token

Generate a long-lived token for your application:

```bash
pnpm amp auth token "30 days"
```

Copy the token and update your `.env`:

```bash
VITE_AMP_QUERY_TOKEN=amp_your_token_here
```

### Step 5: Update Dataset References

In your application code, update queries to reference the published version:

```typescript
// Before (local dev)
const query = 'SELECT * FROM "_/counter@dev".incremented LIMIT 10';

// After (published)
const query =
  'SELECT * FROM "your_namespace/counter@0.0.1".incremented LIMIT 10';
```

Or use `@latest` to always query the most recent published version:

```typescript
const query =
  'SELECT * FROM "your_namespace/counter@latest".incremented LIMIT 10';
```

### Step 6: Query Your Published Dataset

Your dataset is now publicly available. Anyone can query it:

```bash
pnpm amp query \
  --flight-url https://gateway.amp.staging.thegraph.com \
  --bearer-token YOUR_TOKEN \
  'SELECT * FROM "your_namespace/counter@0.0.1".incremented LIMIT 10'
```

**View in registry:** https://playground.amp.thegraph.com/

### Updating Your Dataset

To publish a new version:

1. Update your `amp.config.ts`
2. Increment the version: `pnpm amp publish --tag "0.0.2" --changelog "Added new derived table"`
3. Users can query `@0.0.2` for the new version or `@latest` to automatically use it

### Version Tags

- `@dev` - Local development (unpublished)
- `@0.0.1`, `@1.2.3` - Specific published versions
- `@latest` - Most recent published version (updates automatically)
