---
title: Dataset Configuration
description: Understanding Amp's configuration file
slug: references/configfile
---

## Overview

Amp uses a primary TOML configuration file to define settings for writing and serving datasets. A complete example is available in `config.sample.toml`.

Set the file path using the `AMP_CONFIG` environment variable.

Dataset extraction requires three storage directories:

- `manifests_dir` — Dataset definitions used as input for extraction.
- `providers_dir` — Provider definitions for external data sources such as Firehose.
- `data_dir` — Extracted parquet tables (initially empty on first use).

This structure provides flexibility and modularity across environments.

## Environment Variable Overrides

All configuration values can be overridden using environment variables prefixed with `AMP_CONFIG_`.

### Basic Override

```bash
export AMP_CONFIG_DATA_DIR=/path/to/data
```

### Nested Values

Use double underscores `(__)` to represent nested fields:

| Config Key            | Environment Variable                |
| --------------------- | ----------------------------------- |
| metadata_db.url       | AMP_CONFIG_METADATA_DB\_\_URL       |
| metadata_db.pool_size | AMP_CONFIG_METADATA_DB\_\_POOL_SIZE |
| writer.compression    | AMP_CONFIG_WRITER\_\_COMPRESSION    |

### Service Addresses

Optional keys let you customize host and port bindings:

| Key              | Service                 | Default        |
| ---------------- | ----------------------- | -------------- |
| `flight_addr`    | Arrow Flight RPC server | `0.0.0.0:1602` |
| `jsonl_addr`     | JSON Lines server       | `0.0.0.0:1603` |
| `admin_api_addr` | Admin API server        | `0.0.0.0:1610` |

## Logging

```nginx
error | warn | info | debug | trace
```

Default: `debug`.

For granular control, use `RUST_LOG`.

## Object Store Configuration

Directory fields `(*_dir)` accept either local filesystem paths or object store URLs. Object stores are recommended for production workloads.

### S3-Compatible Stores

#### URL Format

```
s3://<bucket>
```

## Environment Variables

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_DEFAULT_REGION`
- `AWS_ENDPOINT`
- `AWS_SESSION_TOKEN`
- `AWS_ALLOW_HTTP (enables non-TLS)`

## Google Cloud Storage (GCS)

### URL Format

```
gs://<bucket>
``
```

#### Authentication Options

- `GOOGLE_SERVICE_ACCOUNT_PATH`
- `GOOGLE_SERVICE_ACCOUNT_KEY`
- Application Default Credentials (ADC)

## Datasets

### Identity and Versioning

A dataset identity consists of:

- Namespace (e.g., edgeandnode, my*org, or *)
- Name (e.g., eth_mainnet)
- Version/Revision (1.0.0, latest, dev, or a manifest hash)

#### Reference Format

```
namespace/name@revision
```

**Examples**

- `my_org/eth_mainnet@1.0.0`
- `my_org/eth_mainnet@latest`
- `my_org/eth_mainnet@dev`
- `_ /eth_mainnet@latest`

## SQL Schema Names

Datasets appear as quoted schemas in SQL:

```sql
SELECT * FROM "namespace/name".table_name;
```

### Examples

- `"my_org/eth_mainnet".blocks`
- `"my_org/eth_mainnet".logs`

Quoting is required because schema names use `/`.

## Dataset Categories

Amp supports:

- Raw datasets — Directly extracted from external data sources (Firehose, EVM RPC).
- Derived datasets — SQL transformations built on top of existing datasets.

Details for the raw datasets currently implemented:

EVM RPC [dataset docs]()
Firehose [dataset docs]()

## Generating Raw Dataset Manifests

Use `ampctl gen-manifest` to generate JSON manifests defining schema and extraction configuration.

```bash
## Examples

# EVM RPC dataset
ampctl gen-manifest --network mainnet --kind evm-rpc --name eth_mainnet

# With custom start block
ampctl gen-manifest --network mainnet --kind evm-rpc --name eth_mainnet --start-block 1000000

# Firehose dataset
ampctl gen-manifest --network mainnet --kind firehose --name eth_firehose

# Write to a specific file
ampctl gen-manifest --network mainnet --kind evm-rpc --name eth_mainnet -o ./manifests_dir/eth_mainnet.json

# Write to a directory (creates ./manifests/evm-rpc.json)
ampctl gen-manifest --network mainnet --kind evm-rpc --name eth_mainnet -o ./manifests/

# Finalized blocks only
ampctl gen-manifest --network mainnet --kind evm-rpc --name eth_mainnet --finalized-blocks-only
```

### Parameters

| Flag                      | Description                                        |
| ------------------------- | -------------------------------------------------- |
| `--network`               | Target network (mainnet, goerli, polygon, anvil)   |
| `--kind`                  | Dataset type (`evm-rpc`, `firehose`, `eth-beacon`) |
| `--name`                  | Dataset name                                       |
| `--out`, `-o`             | File or directory to write output                  |
| `--start-block`           | Start block (default: 0)                           |
| `--finalized-blocks-only` | Include only finalized blocks                      |

The output manifest includes the complete table and column schema.

## Registering and Deploying Datasets

```bash
# Register dataset (updates dev tag)
ampctl dataset register my_namespace/eth_mainnet ./manifest.json

# Register with a specific version
ampctl dataset register my_namespace/eth_mainnet ./manifest.json --tag 1.0.0

# Deploy for extraction
ampctl dataset deploy my_namespace/eth_mainnet@1.0.0
```

## Providers

Providers define external data sources used to extract raw blockchain data. Each provider is defined in a TOML file stored inside `providers_dir`.

Environment variable substitution is supported using `${VAR_NAME}`.

## Provider Types

Valid values for the `kind` field:

- `evm-rpc1` — Ethereum JSON-RPC (HTTP/WebSocket/IPC)
- `firehose` — Firehose gRPC
- `eth-beacon` — Ethereum Beacon Chain REST API

## Base Structure

Every provider configuration must include:

- `kind`: Provider type
- `network`: Network identifier (e.g., `mainnet`, `goerli`)

Provider name defaults to the filename (minus `.toml`) unless overridden with `name`.

## Sample Provider Configurations

Available sample directory:

- **[evm-rpc.sample.toml](https://github.com/edgeandnode/amp/blob/main/docs/providers/evm-rpc.sample.toml)** - Configuration for Ethereum-compatible JSON-RPC endpoints. Includes fields for URL (HTTP/WebSocket/IPC), concurrent request limits, RPC batching, rate limiting, and receipt fetching options.

- **[firehose.sample.toml](https://github.com/edgeandnode/amp/blob/main/docs/providers/firehose.sample.toml)** - Configuration for StreamingFast Firehose gRPC endpoints. Includes fields for gRPC URL and authentication token.

- **[eth-beacon.sample.toml](https://github.com/edgeandnode/amp/blob/main/docs/providers/eth-beacon.sample.toml)** - Configuration for Ethereum Beacon Chain REST API endpoints. Includes fields for API URL, concurrent request limits, and rate limiting.

Each sample documents required and optional fields along with defaults.
