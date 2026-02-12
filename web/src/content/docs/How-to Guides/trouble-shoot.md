---
title: Troubleshooting
slug: how-to/troubleshoot
category: how-to-guide
---

A collection of common issues and fast, actionable fixes when working with Amp. Each section includes the cause and the steps to resolve it.

### Incorrect Dataset Reference: “Unknown dataset reference '\_/counter@latest'”

**Cause**: Local development datasets require the `@dev` and not `@latest`.

```bash
# Incorrect
pnpm amp query 'SELECT * FROM "_/counter".incremented'

# Correct
pnpm amp query 'SELECT * FROM "_/counter@dev".incremented'
```

> Notes: `@dev` identifies unpublished local datasets. Published datasets use explicit versions (for example, `@1.0.0`) or`@latest`.

### Empty Tables

Cause: No events have been generated yet.

**Fix**:

1. Open http://localhost:5173.
2. Click increment or decrement.
3. Wait a few seconds for new blocks.
4. Run your query again.

Verify events exist:

```bash
# Check if any events have been emitted
pnpm amp query 'SELECT COUNT(*) FROM "_/counter@dev".incremented'
```

### Config Changes Not Applying

**Cause**: Amp caches dataset configurations and must be restarted.

**Fix**:

```bash
just down  # Stop all services and clean volumes
just up    # Restart infrastructure and redeploy
```

### Dataset Not Deploying

**Symptoms**:

- `“dataset not found”`
- Missing directory under `infra/amp/data/`
- Build succeeds but no tables appear

**Debug Steps**:

1. Check logs

```bash
docker compose -f infra/docker-compose.yaml logs amp | grep counter
```

2. Verify data directory

```bash
ls -la infra/amp/data/
```

You should see a counter/ directory.

3. Deploy manually

```bash
pnpm ampctl dataset deploy _/counter@dev
```

4. Validate configuration

```bash
pnpm amp build -o /tmp/test-manifest.json
```

**Common Causes**:

- SQL syntax errors
- Violations of streaming model rules
- Services not fully started (wait for just up to complete)
- Local Anvil connectivity issues

### Build Errors

#### “non-incremental operation: Limit”

**Cause**: `LIMIT` is not allowed in derived table definitions.

**Fix**: Use filters in table definitions and apply `LIMIT` only during queries.

```typecript
// Invalid
sql: `SELECT * FROM anvil.blocks LIMIT 100`

// Valid
sql: `SELECT * FROM anvil.blocks WHERE _block_num > 100`
```

Query:

```bash
pnpm amp query 'SELECT * FROM "_/counter@dev".all_blocks LIMIT 100'
```

#### “non-incremental operation: Order”

Remove `ORDER BY` from table definitions. Use it only at query time.

```bash
pnpm amp query 'SELECT * FROM "_/counter@dev".incremented ORDER BY block_num DESC'
```

#### “non-incremental operation: Aggregate”

Aggregations (`GROUP BY`, `COUNT`, `SUM`) are not allowed in table definitions.

Use them during queries:

```bash
pnpm amp query '
  SELECT block_num, COUNT(*) AS event_count
  FROM "_/counter@dev".incremented
  GROUP BY block_num
'
```

#### “invalid value 'dev' for '--tag'”

**Cause**: Using `-t dev`.

**Fix**: Use the dataset tag inside the reference:

```bash
# Incorrect
pnpm amp query -t dev 'SELECT * FROM "_/counter".incremented'

# Correct
pnpm amp query 'SELECT * FROM "_/counter@dev".incremented'
```

### Services Not Starting

_Symptoms_: Hanging `just up`, crashing containers, port conflicts.

_Fixes_:

1. Check Docker:

```bash
docker ps
```

2. Check port conflicts:

```bash
lsof -i :5432
lsof -i :8545
lsof -i :1602
```

3. Stop conflicting services:

```bash
brew services stop postgresql
killall anvil
```

4. Reset Docker state:

```bash
just down
docker system prune -f
just up
```

5. Verify toolchain versions:

```bash
node --version
pnpm --version
docker --version
forge --version
just --version
amp --version
```

## Query Timeouts

**Cause**: Large result sets or complex joins.

**Fixes**:

1. Add `LIMIT`:

```bash
pnpm amp query 'SELECT * FROM anvil.blocks LIMIT 100'
```

2. Filter by indexed columns:

```bash
pnpm amp query '
  SELECT * FROM anvil.logs
  WHERE address = '\''0x...'\''
  LIMIT 10
'
```

3. Create pre-filtered derived tables:

```typecript
sql: `SELECT * FROM anvil.logs WHERE address = '0x...'`
```

4. Check service health:

```bash
docker compose -f infra/docker-compose.yaml ps
docker compose -f infra/docker-compose.yaml logs amp
```

### Frontend Not Connecting

**Symptoms**: Data not loading, network errors, “Failed to fetch.”

**Fixes**:

1. Ensure dev server is running:

```bash
just dev
```

2. Verify app/.env:

```bash
cat app/.env
```

3. Confirm dataset deployment:

```bash
pnpm amp query 'SELECT COUNT(*) FROM "_/counter@dev".incremented'
```

4. Inspect browser console.

### Advanced Debugging

#### Connect to PostgreSQL

```bash
open http://localhost:7402

docker exec -it amp-postgres psql -U postgres -d amp
```

**Useful queries**:

```sql
SELECT * FROM datasets;
SELECT name, status, error FROM datasets WHERE name = 'counter';
```

#### View Detailed Logs

```bash
just logs
docker compose -f infra/docker-compose.yaml logs -f amp
docker compose -f infra/docker-compose.yaml logs amp | grep ERROR
```

#### Reset System State

```bash
just down
rm -rf infra/amp/data/
rm -rf infra/amp/datasets/
just up
```

#### Test Anvil Connectivity

```bash
curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
```

#### Validate Dataset Build

```bash
pnpm amp build -o /tmp/manifest.json
cat /tmp/manifest.json | jq
```

### Common Error Messages

**“table does not exist”**

- Confirm table exists in amp.config.ts.
- Restart services: just down && just up.
- Verify dataset reference includes tag.

**“column does not exist”**

```bash
pnpm amp query 'DESCRIBE "_/counter@dev".incremented'
```

Check naming and case sensitivity.

**“parse error”**

- Validate SQL syntax.
- Ensure dataset references are quoted.
- Validate escaping.

**“cannot read properties of undefined”**
(FE runtime error)

- Log data to ensure response exists.
- Gate UI logic on presence of data.

### Performance Issues

**Slow Queries**

- Filter datasets.
- Use EXPLAIN:

```bash
pnpm amp query 'EXPLAIN SELECT * FROM anvil.blocks'
```

- Limit data by block range.

**High Memory Usage**

- Reduce result size.
- Split large tables into focused tables.
- Restart services (`just down && just up`).
