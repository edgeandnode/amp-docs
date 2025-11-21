---
title: SQL UDF
description: Understand SQL references
slug: references/sqludf
category: references
---

A concise reference for SQL syntax and UDFs used in Amp dataset queries.

## Core UDFs

### `evm_decode()`

Decodes Ethereum event log data into a structured format.

**Syntax**

```sql
    evm_decode(topic1, topic2, topic3, data, signature_string)
```

**Parameters:**

- `topic1, topic2, topic3` - Indexed event parameters (or NULL)
- `data` - Non-indexed event data from log
- `signature_string` - Event signature with parameter names and types

**Returns**
Struct matching the event signature.

#### Example

```sql
evm_decode(
  l.topic1, l.topic2, l.topic3, l.data,
  'Supply(address indexed reserve,address user,address indexed onBehalfOf,uint256 amount,uint16 indexed referral)'
) AS event
```

#### Access Fields

```sql
event['reserve']
event['amount']
event['referral']
```

#### Signature Patterns

| Solidity Type | Signature Syntax                                            |
| ------------- | ----------------------------------------------------------- |
| Address       | `address`, `address indexed`                                |
| Unsigned int  | `uint256`, `uint128`, `uint64`, `uint32`, `uint16`, `uint8` |
| Signed int    | `int256`, `int128`, etc.                                    |
| Boolean       | `bool`                                                      |
| String        | `string`                                                    |
| Bytes         | `bytes`, `bytes32`, `bytes20`                               |
| Array         | `uint256[]`, `address[]`, `uint256[2]` (fixed size)         |

> Notes

    -  `indexed` parameters appear in topic1/topic2/topic3
    - Non-indexed parameters appear in data field
    - Event signature determines which is which

### `evm_topic()`

Computes the keccak256 hash of an event signature.

**Syntax:**

```sql
evm_topic(event_signature)
```

**Parameters:**

- `event_signature` - Event signature WITHOUT parameter names

**Returns**
32-byte hash (topic0)

#### Example

```sql
WHERE l.topic0 = evm_topic('Transfer(address,address,uint256)')
```

> **IMPORTANT**
> Rules

- Do NOT include parameter names: `'Transfer(address,address,uint256)'`
- Do NOT use spaces: `'Transfer(address, address, uint256)'`
- Match parameter order exactly with contract ABI

#### Common Event Signatures

```sql
evm_topic('Transfer(address,address,uint256)')
evm_topic('Approval(address,address,uint256)')
evm_topic('Swap(address,uint256,uint256,uint256,uint256,address)')
evm_topic('Supply(address,address,address,uint256,uint16)')
evm_topic('Withdraw(address,address,address,uint256)')
```

### `arrow_cast()`

Converts values between Apache Arrow types.

**Syntax:**

```sql
arrow_cast(value, 'target_type')
```

#### Common Conversions

| Use Case               | Example                                             |
| ---------------------- | --------------------------------------------------- |
| Hex to address         | `arrow_cast(x'1234...', 'FixedSizeBinary(20)')`     |
| Hex to tx hash         | `arrow_cast(x'abcd...', 'FixedSizeBinary(32)')`     |
| Field to address       | `arrow_cast(l.address, 'FixedSizeBinary(20)')`      |
| Event field to address | `arrow_cast(event['token'], 'FixedSizeBinary(20)')` |
| String to uint         | `arrow_cast(event['amount'], 'UInt64')`             |
| String to uint256      | Keep as `Utf8` (too large for UInt64)               |

#### Address Filter

```sql
WHERE l.address = arrow_cast(x'1234567890abcdef...', 'FixedSizeBinary(20)')
```

#### Type Casting in SELECT

```sql
SELECT
  arrow_cast(event['token0'], 'FixedSizeBinary(20)') AS token0,
  arrow_cast(event['pair_index'], 'UInt64') AS pair_index
```

## Standard Query Pattern

### Basic Event Query

```sql
WITH decoded AS (
  SELECT
    l.block_num,
    l.timestamp,
    l.tx_hash,
    l.log_index,
    l.address AS contract_address,
    evm_decode(
      l.topic1, l.topic2, l.topic3, l.data,
      'EventName(param1_type indexed param1_name,param2_type param2_name,...)'
    ) AS event
  FROM eth_firehose.logs l
  WHERE l.address = x'CONTRACT_ADDRESS_HEX'
    AND l.topic0 = evm_topic('EventName(param1_type,param2_type,...)')
)
SELECT
  block_num,
  timestamp,
  tx_hash,
  log_index,
  contract_address,
  event['param1_name'] AS param1,
  event['param2_name'] AS param2
FROM decoded
```

> System adds `_block_num` automatically; do not select it.

## Log Fields

```sql
l.block_num          -- UInt64
l.timestamp          -- Timestamp(Nanosecond, "+00:00")
l.tx_hash            -- FixedSizeBinary(32)
l.log_index          -- UInt32
l.address            -- FixedSizeBinary(20) - contract address
l.topic0             -- Event signature hash
l.topic1             -- First indexed parameter
l.topic2             -- Second indexed parameter
l.topic3             -- Third indexed parameter
l.data               -- Non-indexed parameters (encoded)
```

## Common SELECT Fields

```sql
SELECT
  block_num,                    -- Always include
  timestamp,                    -- Always include
  tx_hash,                      -- Always include
  log_index,                    -- Always include for uniqueness
  contract_address,             -- Or pool_address, factory_address, etc.
  event['field1'] AS field1,    -- Decoded event fields
  event['field2'] AS field2
FROM decoded
```

## Filtering Patterns

### Single Contract

```sql
WHERE l.address = x'CONTRACT_HEX'
  AND l.topic0 = evm_topic('EventName(...)')
```

### Multiple Contracts (OR)

```sql
WHERE l.address IN (
    arrow_cast(x'CONTRACT1_HEX', 'FixedSizeBinary(20)'),
    arrow_cast(x'CONTRACT2_HEX', 'FixedSizeBinary(20)')
  )
  AND l.topic0 = evm_topic('EventName(...)')
```

### Multiple Events (OR)

```sql
WHERE l.address = arrow_cast(x'CONTRACT_HEX', 'FixedSizeBinary(20)')
  AND l.topic0 IN (
    evm_topic('Event1(...)'),
    evm_topic('Event2(...)')
  )
```

### Filter by Indexed Parameter

```sql
WHERE l.address = x'CONTRACT_HEX'
  AND l.topic0 = evm_topic('Transfer(address,address,uint256)')
  AND l.topic1 = x'FROM_ADDRESS_HEX'
```

> Indexed addresses are 32-byte padded.

## Array and Complex Types

### Fixed-Size Arrays

**Signature example:**

```bash
'AddLiquidity(address indexed provider,uint256[2] token_amounts,uint256[2] fees,...)'
```

**Access:**

```sql
event['token_amounts']    -- Returns array as-is
event['fees']             -- Returns array as-is
```

## Type Safety Tips

| Data                          | Type                  | Reason                                |
| ----------------------------- | --------------------- | ------------------------------------- |
| uint8, uint16, uint32, uint64 | `UInt64`              | Fits in 64 bits                       |
| uint128, uint256              | `Utf8`                | Too large for UInt64                  |
| Token amounts                 | `Utf8`                | Usually uint256, avoid precision loss |
| Counts, IDs < 2^64            | `UInt64`              | Safe for integer operations           |
| Addresses                     | `FixedSizeBinary(20)` | 20 bytes                              |
| Transaction hashes            | `FixedSizeBinary(32)` | 32 bytes                              |

### Using Decimal Types for Large Numbers

For arithmetic operations on large integers, use Decimal or Double types:

| Solidity Type | Decimal Type       | Notes            |
| ------------- | ------------------ | ---------------- |
| uint128       | `Decimal128(38,0)` | Up to 38 digits  |
| uint256       | `Decimal256(76,0)` | Up to 76 digits  |

```sql
-- Cast Utf8 to Decimal for arithmetic
SELECT
  arrow_cast(token_amount, 'Decimal256(76,0)') * price AS value
FROM transfers
```

The `0` scale means no decimal places (integer math).

There is no perfect conversion of Solidity uint256 to Arrow. `Decimal256(76,0)` preserves full precision, however does not capture the full numeric range of the binary Solidity uint256. Any realistic monetary value will fit in a `Decimal256`, but if your uint256 is a random identifier it might be best represented as `Utf8`. FLOAT or DOUBLE can lose precision but may be suitable for aggregations.

### Mismatched Signature in decode

```sql
evm_decode(
  l.topic1, l.topic2, l.topic3, l.data,
  'Supply(address reserve,address user,...)'  -- Missing 'indexed'
)
```

### Correct - Match ABI

```sql
evm_decode(
  l.topic1, l.topic2, l.topic3, l.data,
  'Supply(address indexed reserve,address user,...)'  --  Matches which params are indexed
)
```

### Incorrect Address Type

```sql
WHERE l.address = '0x1234...'  -- String literal
```

### Correct Type

```sql
WHERE l.address = x'1234...'
```

## Advanced Patterns

### Multiple CTEs

```sql
WITH decoded_supply AS (
  SELECT ...
  FROM eth_firehose.logs l
  WHERE ...
),
decoded_withdraw AS (
  SELECT ...
  FROM eth_firehose.logs l
  WHERE ...
)
SELECT * FROM decoded_supply
UNION ALL
SELECT * FROM decoded_withdraw
```

### Nested Subqueries

```sql
SELECT
  outer_field,
  transformed_field
FROM (
  SELECT
    block_num,
    event['amount'] AS amount,
    arrow_cast(event['amount'], 'UInt64') AS amount_numeric
  FROM (
    WITH decoded AS (...)
    SELECT * FROM decoded
  )
)
WHERE amount_numeric > 1000
```

## Quick Examples

### Transfer Event

```sql
WITH decoded AS (
  SELECT
    l.block_num,
    l.timestamp,
    l.tx_hash,
    l.log_index,
    evm_decode(
      l.topic1, l.topic2, l.topic3, l.data,
      'Transfer(address indexed from,address indexed to,uint256 value)'
    ) AS event
  FROM eth_firehose.logs l
  WHERE l.address = x'TOKEN_ADDRESS'
    AND l.topic0 = evm_topic('Transfer(address,address,uint256)')
)
SELECT
  block_num,
  timestamp,
  tx_hash,
  log_index,
  arrow_cast(event['from'], 'FixedSizeBinary(20)') AS from_address,
  arrow_cast(event['to'], 'FixedSizeBinary(20)') AS to_address,
  event['value'] AS value
FROM decoded
```

### Event with Multiple Indexed Parameters

```sql
WITH decoded AS (
  SELECT
    l.block_num,
    l.timestamp,
    l.tx_hash,
    l.log_index,
    evm_decode(
      l.topic1, l.topic2, l.topic3, l.data,
      'Swap(address indexed sender,uint256 amount0In,uint256 amount1In,uint256 amount0Out,uint256 amount1Out,address indexed to)'
    ) AS event
  FROM eth_firehose.logs l
  WHERE l.address = x'PAIR_ADDRESS'
    AND l.topic0 = evm_topic('Swap(address,uint256,uint256,uint256,uint256,address)')
)
SELECT
  block_num,
  timestamp,
  tx_hash,
  log_index,
  arrow_cast(event['sender'], 'FixedSizeBinary(20)') AS sender,
  event['amount0In'] AS amount0_in,
  event['amount1In'] AS amount1_in,
  event['amount0Out'] AS amount0_out,
  event['amount1Out'] AS amount1_out,
  arrow_cast(event['to'], 'FixedSizeBinary(20)') AS to_address
FROM decoded
```
