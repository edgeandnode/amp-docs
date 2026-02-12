---
title: Streaming SQL
slug: how-to/streamsql
category: how-to-guide
---

Amp processes blockchain data as a continuous stream. When you define a derived table, Amp incrementally updates it as new blocks arrive. SQL used in derived table definitions must be incrementally updatable so Amp can append new rows without recomputing the entire dataset.

## How Streaming Works

Amp applies your SQL definition every time new chain data arrives:

- Reads new blocks/logs
- Runs your SQL against the new rows
- Appends results to the derived table
- Repeats for each new block

> Important: Your SQL must work correctly when run incrementally. Operations that require seeing all data at once (like `GROUP BY` with aggregates) don't work in this model.

## Common Patterns for Streaming SQL

### 1. Pre-Filter High-Volume Tables

Reduce a large dataset into something query-efficient.

```ts
usdc_transfers: {
  sql: `
    SELECT *
    FROM anvil.logs
    WHERE address = '0xUSDC...'
      AND topic0 = '0xddf252ad...'
  `,
}
```

### 2. Enrich Events with Block Metadata

Attach timestamps and context to events.

```ts
transfers_with_time: {
  sql: `
    SELECT
      l.address,
      l.data,
      b.timestamp
    FROM anvil.logs l
    JOIN anvil.blocks b ON l.block_num = b.block_num
  `,
}
```

### 3. Combine Event Types with UNION ALL

```ts
all_value_transfers: {
  sql: `
    SELECT block_num, from_addr, to_addr, value, 'eth' AS type
    FROM anvil.transactions
    WHERE value > 0

    UNION ALL

    SELECT block_num, from_addr, to_addr, value, 'token' AS type
    FROM "_/erc20@dev".transfers
  `,
}
```

### 4. Decode Logs Using UDFs

```ts
decoded_swaps: {
  sql: `
    SELECT
      block_num,
      evm_decode_log(data, topics, 'event Swap(...)') AS decoded
    FROM anvil.logs
    WHERE topic0 = evm_topic('Swap(...)')
  `,
}
```

## Testing Your SQL

### 1. Prototype in Amp Studio

```bash
just studio
```

### 2. Validate Build

```bash
pnpm amp build -o /tmp/test-manifest.json
```

### 3. Deploy and Query

```bash
just down
just up
pnpm amp query 'SELECT * FROM "_/dataset@dev".table LIMIT 5'
```

## Performance Tips

- Filter early
- Select only needed columns
- Use indexed columns (`address`, `block_num`)
- Move expensive operations (sorting, grouping, limiting) to query time

## When to Use Derived Tables

Use derived tables when:

- You repeatedly query the same filtered/joined data
- You need sub-second query latency
- The transformation is streaming-compatible

## When to Use Query-Time SQL

Use query-time SQL when:

- You need aggregates (COUNT, SUM, etc.)
- You need sorting or deduplication
- You’re exploring data ad-hoc

### Examples From the Template

The (Quickstart)[] includes additional working examples showing:

- Filtering dependency tables
- Joining blocks and transactions
- Using UDFs (e.g. `evm_decode_log`)
- Correct streaming-compatible SQL structure

You can view them here:

```bash
cat amp.config.extended-example.ts
```

These examples illustrate complete, real-world derived table definitions.

## Need Help?

- SQL syntax reference: [DuckDB SQL](https://duckdb.org/docs/sql/introduction)
- Performance tuning: See [Streaming SQL Reference](/references/streamingsql/)
