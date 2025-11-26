---
title: Streaming SQL
description: Understand Streaming SQL references
slug: references/streamingsql
category: references
---

Amp updates derived tables incrementally. SQL inside a derived table definition must be incrementally computable.

## Supported Operations

### Filtering

```sql
SELECT * FROM anvil.logs WHERE value > 0
```

### Projections & Renaming

```sql
SELECT block_num, hash AS block_hash FROM anvil.blocks
```

### Transformations

```sql
SELECT gas_used * 100 / gas_limit AS pct FROM anvil.blocks
```

### Joins (Dependency Tables Only)

```sql
SELECT t.hash, b.timestamp
FROM anvil.transactions t
JOIN anvil.blocks b ON t.block_num = b.block_num
```

### UNION ALL

```sql
SELECT * FROM a.transfers
UNION ALL
SELECT * FROM b.transfers
```

### CASE Expressions

```sql
SELECT gas_used,
  CASE WHEN gas_used < 21000 THEN 'minimal' END AS complexity
FROM anvil.transactions
```

## Unsupported Operations

Not allowed inside derived table definitions:

- `LIMIT`/ `OFFSET`
- `ORDER BY` (global)
- `GROUP BY` with aggregates
- `DISTINCT`
- Window functions
- Non-deterministic functions
- Self-referencing tables

Use these at **query time** instead.

### Example Derived Table Definition

```ts
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
}
```

## Need Help?

- SQL syntax reference: [DuckDB SQL](https://duckdb.org/docs/sql/introduction)
- Performance tuning: See Performance Tips in [Streaming SQL Guide](/how-to/streamsql/)
