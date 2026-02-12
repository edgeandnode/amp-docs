---
title: Operational Modes & Deployment Patterns
description: Learn how about Amp's different operational modes and choose the right deployment pattern for your environment.
slug: references/operationalmodes
category: reference
---

This page is a technical reference for Amp's operational modes, components, and deployment patterns. It’s intended for engineers designing, deploying, or operating Amp in development and production environments.

## 1. Overview

Amp provides several core commands that can be composed into different deployment strategies:

- **`server`** — Query server exposing Arrow Flight and JSON Lines interfaces
- **`worker`** — Executes scheduled extraction jobs
- **`controller`** — Hosts the Admin API for job and dataset management
- **`migrate`** — Applies metadata database migrations

Amp supports two primary operational modes:

- **Single-Node Mode** — All components run together (local dev/testing)
- **Distributed Mode** — Components deployed independently (production)

## 2. Operational Modes

### 2.1 Single-Node Mode

Single-node mode runs all components in one process.

- Server, controller, and worker run together
- Activated via `ampd dev`
- Optimized for:
  - Local development
  - CI pipelines
  - Quick testing and prototyping
- Not designed for production reliability or fault isolation

### 2.2 Distributed Mode

Distributed mode separates components into independent processes.

- Server, controller, and workers run separately
- Suitable for production deployments
- Enables:
  - Horizontal scaling
  - Resource isolation (queries vs extraction)
  - High availability and failover

## 3. Core Components

### 3.1 Server Component

#### Purpose

- Exposes query interfaces (Arrow Flight and JSON Lines)
- Serves data only
- Does **not** execute extraction jobs
- Does **not** provide management APIs

#### Query Interfaces

- **Arrow Flight (port 1602)**
  - High-performance binary interface
  - gRPC-based
  - Uses Apache Arrow / Flight SQL

- **JSON Lines (port 1603)**
  - HTTP `POST` interface
  - Returns newline-delimited JSON (NDJSON)
  - Supports streaming and compression (gzip, brotli, deflate)

#### Basic Usage

```bash
# Start both query servers (default)
ampd server

# Start only the Arrow Flight server
ampd server --flight-server

# Start only the JSON Lines server
ampd server --jsonl-server

# Start both explicitly
ampd server --flight-server --jsonl-server
```

#### JSON Lines Query Example

```bash
curl -X POST http://localhost:1603 \
  --data "SELECT * FROM 'ns/eth_mainnet'.blocks LIMIT 10"
```

#### Arrow Flight Example (Python)

```python
Copy code
from pyarrow import flight

client = flight.connect("grpc://localhost:1602")
reader = client.do_get(
    flight.Ticket("SELECT * FROM 'ns/eth_mainnet'.blocks LIMIT 10")
)
table = reader.read_all()
print(table.to_pandas())
```

> Without flags, both query servers are enabled by default. When you specify any server flags, only those interfaces are enabled.

### 3.2 Worker Component

#### Purpose

The worker executes scheduled extraction jobs in distributed deployments.

- Runs as a standalone process
- Coordinates with other components via the PostgreSQL metadata database

#### Responsibilities\*\*

Workers:

- Register with the metadata DB using a node ID
- Send heartbeat signals (health)
- Listen for job notifications (LISTEN/NOTIFY)
- Execute dump jobs (pull data, write Parquet files)
- Update job status and file metadata
- Resume jobs after restarts
- Periodically reconcile job state with the metadata DB

#### Basic Usage

```bash
# Single worker

ampd worker --node-id worker-01

# Multiple workers for parallel extraction

ampd worker --node-id worker-01 &
ampd worker --node-id worker-02 &
ampd worker --node-id worker-03 &
```

Workers can use descriptive IDs, for example:

```bash
ampd worker --node-id eu-west-1a-worker
ampd worker --node-id us-east-1b-worker
```

### 3.3 Controller Component

#### Purpose

The controller provides the Admin API for managing Amp:

- Dataset management
- Job creation and control
- Worker and file metadata visibility

It runs as a standalone service and is typically deployed separately from the query server.

#### Admin API

- Default port: 1610
- REST-style management interface
- Operations include:
  - Dataset registration and versioning
  - Job deployment and status inspection
  - Job stop/delete operations
  - Worker location and file listing

#### Basic Usage

```bash
ampd controller
```

### Example: Dataset Management

```bash
# List all datasets

curl http://localhost:1610/datasets

# Get dataset details (specific version)

curl http://localhost:1610/datasets/my_namespace/eth_mainnet/versions/1.0.0

# List all versions of a dataset

curl http://localhost:1610/datasets/my_namespace/eth_mainnet/versions

# Register a new dataset

curl -X POST http://localhost:1610/datasets \
 -H "Content-Type: application/json" \
 -d @dataset_definition.json
```

### Example: Job Control

```bash
# List all jobs

curl http://localhost:1610/jobs

# Deploy a dataset (start a dump job)

curl -X POST http://localhost:1610/datasets/my_namespace/eth_mainnet/versions/1.0.0/deploy \
 -H "Content-Type: application/json" \
 -d '{
"end_block": 20000000
}'

# Get job status (replace 42 with actual job_id)

curl http://localhost:1610/jobs/42

# Stop a running job

curl -X PUT http://localhost:1610/jobs/42/stop

# Delete a job

curl -X DELETE http://localhost:1610/jobs/42
```

> In development mode (`ampd dev`), the controller (Admin API) is embedded in the same process as the server.

## 4. Development Mode (Single-Node)

### Purpose

Development mode runs all components in a single process and is optimized for:

- Local development
- Quick prototyping
- CI and automated testing
- Learning how Amp behaves end-to-end

> Not recommended for production deployments.

### How It Works

When you run `ampd dev`:

1. Server starts (Arrow Flight + JSON Lines)
2. Controller (Admin API) starts in the same process
3. Embedded worker starts with node ID worker
4. Worker registers with the metadata DB and listens for jobs
5. Jobs scheduled via Admin API run inside this single process
6. Logging and errors are centralized for easier debugging

#### Basic Usage

```bash
# Start development mode
ampd dev
```

Schedule a job:

```bash
curl -X POST http://localhost:1610/datasets/my_namespace/eth_mainnet/versions/dev/deploy \
 -H "Content-Type: application/json" \
 -d '{
"end_block": 1000000
}'
```

#### Query the data:

```bash
curl -X POST http://localhost:1603 \
 --data "SELECT COUNT(\*) FROM 'my_namespace/eth_mainnet'.blocks"
```

### Benefits

- Single process, minimal setup
- No separate worker or controller configuration
- Fast iteration loops

### Limitations

- No fault isolation (worker crash kills the process)
- Resource contention between queries and extraction
- No horizontal scaling or high availability
- Not production-grade

## 5. Deployment Patterns

This section outlines common deployment topologies and when to use them.

### 5.1 Pattern: Development Mode (Single-Node)

Use when:

- Local development and testing
- CI environments
- Prototyping

Command:

```bash
ampd dev
```

### 5.2 Pattern: Query-Only Server (Distributed, Read-Only)

Use when:

- You only need read-only query serving
- Datasets are populated by external extraction processes
- You want multiple query replicas for load balancing

Commands:

```bash
ampd server
```

### 5.3 Pattern: Server + Controller + Workers (Full Distributed)

Use when:

- Production deployments
- You need resource isolation between queries and extraction
- You need horizontal scaling and high availability

Commands:

```bash
# Server node(s)

ampd server

# Controller node

ampd controller

# Worker node(s)

ampd worker --node-id worker-01
ampd worker --node-id worker-02
ampd worker --node-id worker-03
```

### 5.4 Pattern: Multi-Region Distributed

Use when:

- You need global low-latency query access
- You want geographic redundancy
- You’re operating large-scale production systems

Example Commands:

```bash
# Region A

ampd server
ampd controller
ampd worker --node-id us-east-1-worker

# Region B

ampd server
ampd worker --node-id eu-west-1-worker
```

## 6. Choosing Between Modes

### Use Single-Node Mode (ampd dev) When:

- You’re developing locally
- You’re running tests or quick prototypes
- You want a simple, all-in-one workflow

> Not appropriate for production workloads.

### Use Distributed Mode When:

#### Query-only server:

- You need read-only query serving
- Datasets are populated externally
- You need multiple query replicas

#### Controller-only:

- You need a management interface in a private network
- Query serving is handled elsewhere
- You focus on job scheduling and monitoring

#### Controller + Server + Workers:

- You’re running in production
- You need resource isolation and scaling
- You require high availability and continuous ingestion
- You’re operating in single or multiple regions

## 7. Scaling Path

Recommended progression as your deployment grows:

### Stage 1: Development & Testing

- Mode: Single-node
- Command: `ampd dev`
- Single machine, minimal setup
- Not for production use

### Stage 2: Production Single-Region

- Mode: Distributed
- Deploy `ampd controller` on a management node
- Deploy `ampd server` on one or more query nodes
- eploy `ampd worker --node-id <id>` on extraction nodes
- Enable observability (e.g., OpenTelemetry)
- Configure compaction and retention

### Stage 3: Scaled Distributed Extraction

- Mode: Distributed (scaled)
- Multiple servers for query load balancing
- Multiple workers for parallel extraction
- Shared PostgreSQL and object store

### Stage 4: Multi-Region Production

- Mode: Distributed (global)
- Controller in a primary region
- Servers in multiple regions for low-latency queries
- Workers close to data sources
- Shared global metadata DB and object store

## 8. Security Considerations

Separation of controller, server, and worker components enables fine-grained security via network isolation and access controls.

### Component Security Profiles

**Controller (Admin API — Port 1610)**
Security level: Most sensitive

Capabilities:

- Schedule, start, stop, delete jobs
- Register and modify datasets
- Monitor workers
- Access file metadata

Requirements:

- Must run in a private network
- Must not be exposed to the public internet
- Restrict access to authorized operators only
- Recommended behind VPN or bastion host
- Strict firewall rules and IP allowlists

**Server (Query Interfaces — Ports 1602, 1603)**
Security level: Medium, potentially public-facing

Capabilities:

- Query-only access (read)
- No dataset or job management

Requirements:

- Can be exposed publicly if needed
- Implement rate limiting and timeouts
- Monitor for abusive or expensive queries
- Optionally put behind API gateway for auth
- Prefer read-only DB access where possible

**\Worker (No Exposed Ports)**
Security level: Internal component

Capabilities:

- Execute extraction jobs
- Write to object store
- Update metadata DB

Requirements:

- Runs in trusted/private network
- Needs DB write access and object store write access
- No inbound network access required

## Authentication & Authorization

Current state: Amp components do not ship with built-in auth.

Security relies on:

1. Network isolation (VPCs, subnets, firewalls)
2. Database authentication (PostgreSQL credentials)
3. Object store authentication (e.g., IAM roles, service accounts)

Recommended external layers:

- **API Gateway / Reverse Proxy**
  - e.g., Nginx, Traefik, cloud API gateways
  - API keys, JWT, OAuth2/OIDC

- **Mutual TLS (mTLS)**
  - Client certificate validation
  - Particularly relevant for Arrow Flight (gRPC)

- **VPN / Zero Trust**
  - WireGuard, Tailscale, or cloud VPNs
  - Mandatory for controller access

- **Network Policies**
  - Kubernetes NetworkPolicies
  - Cloud security groups / firewall rules

## Secrets Management

Required secrets typically include:

- PostgreSQL connection strings
- Object store credentials
- Blockchain RPC keys
- Firehose tokens (if applicable)

Recommendations:

- Never commit secrets to version control
- Use secret managers:
  - Kubernetes Secrets
  - AWS Secrets Manager
  - GCP Secret Manager
  - HashiCorp Vault
  - Azure Key Vault
- Inject secrets via environment variables or secret volumes
- Rotate credentials regularly
- Prefer IAM roles / service accounts over static keys

## 9. Threat Model Summary

| Component  | Threat Level | Attack Surface          | Mitigation                                    |
| ---------- | ------------ | ----------------------- | --------------------------------------------- |
| Controller | High         | Admin API (1610)        | Private network, VPN, audit logging           |
| Server     | Medium       | Query APIs (1602/1603)  | Rate limiting, read-only DB, DDoS protections |
| Worker     | Low          | None (no inbound ports) | Private network, minimal outbound access      |
| Dev Mode   | Critical     | All services combined   | Do not use in production                      |
