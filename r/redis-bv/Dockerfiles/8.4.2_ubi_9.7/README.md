# Redis 8.4.2 with Modules for ppc64le (Power Architecture)

This repository contains the build configuration for Redis 8.4.2 with four essential modules compiled for ppc64le architecture and deployed on OpenShift.

## Overview

Custom Redis 8.4.2 image with the following modules:
- **RedisBloom** - Probabilistic data structures
- **RediSearch** - Full-text search and indexing
- **RedisJSON** - Native JSON data type
- **RedisTimeSeries** - Time-series data structures

## Architecture

- **Target Platform**: ppc64le (IBM POWER)
- **Base Image**: Red Hat UBI 9.7
- **Redis Version**: 8.4.2
- **Bitnami Structure**: 8.6.3 (8.4.2 Bitnami variant not available yet)
- **Deployment**: OpenShift with Bitnami Helm Chart

## Important Note

This build uses a **hybrid approach**:
- **Redis Source**: 8.4.2 (from https://github.com/redis/redis)
- **Bitnami Configuration**: 8.6.3 (from https://github.com/bitnami/containers)

This is necessary because Bitnami has not yet released a packaged version for Redis 8.4.2. The Bitnami 8.6 configuration files and scripts are compatible with Redis 8.4.2.

## Files

### Dockerfile
Multi-stage build that:
1. Builds secure utilities (gosu, wait-for-port) with Go 1.26.3
2. Downloads Bitnami 8.6.3 prebuildfs for configuration
3. Compiles Redis 8.4.2 from source with all 4 modules
4. Creates final image with runtime dependencies only


### values.yaml (Example)
Helm chart configuration for deploying Redis on OpenShift:
- Custom image from OpenShift internal registry
- All 4 modules configured via `commonConfiguration`
- Standalone architecture (no replication)
- Resource limits and security settings

```yaml
global:
  security:
    allowInsecureImages: true

architecture: standalone
fullnameOverride: "hcl-commerce-redis"

replica:
  replicaCount: 1

image:
  registry: image-registry.openshift-image-registry.svc:5000
  repository: redislatest/bit-redis
  tag: 8.4.2

auth:
  enabled: false

commonConfiguration: |-
  appendonly no
  save ""
  maxmemory 1000mb
  maxmemory-policy volatile-lru
  loadmodule /opt/bitnami/redis/lib/redis/modules/redisbloom.so
  loadmodule /opt/bitnami/redis/lib/redis/modules/redisearch.so
  loadmodule /opt/bitnami/redis/lib/redis/modules/rejson.so
  loadmodule /opt/bitnami/redis/lib/redis/modules/redistimeseries.so

master:
  disableCommands: []
  persistence:
    enabled: false
  resources:
    limits:
      cpu: 2000m
      memory: 4Gi
    requests:
      cpu: 500m
      memory: 2Gi
```

### redis-bv_8.4.2.patch
Patch file containing fixes for:
- ppc64le register logging in debug.c
- ppc64le backtrace workaround in util.tcl
- Compatible with Redis 8.4.2 (same as 8.4.1 patch)

## Building the Image

```bash
# Navigate to the package directory
cd r/redis-bv

# Build the image (build context is current directory, Dockerfile is in subdirectory)
podman build -t redis-modules:8.4.2 -f Dockerfiles/8.4.2_ubi_9.7/Dockerfile .

# Tag for OpenShift registry
podman tag redis-modules:8.4.2 image-registry.openshift-image-registry.svc:5000/your-namespace/bit-redis:8.4.2

# Push to OpenShift
podman push image-registry.openshift-image-registry.svc:5000/your-namespace/bit-redis:8.4.2
```

## Deploying to OpenShift

### Prerequisites
1. OpenShift cluster with internal registry enabled
2. Helm 3.x installed
3. Bitnami Redis Helm chart repository added

### Deployment Steps

```bash
# Add Bitnami Helm repository
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Create namespace
oc new-project redis-namespace

# Create service account
oc create serviceaccount hcl-commerce-redis -n redis-namespace

# Grant privileged SCC (if required)
oc adm policy add-scc-to-user privileged -z hcl-commerce-redis -n redis-namespace

# Install Redis with Helm
helm install redis-deployment bitnami/redis \
  -n redis-namespace \
  -f values.yaml \
  --version 24.1.8
```

### Verify Deployment

```bash
# Check pod status
oc get pods -n redis-namespace

# Verify all 4 modules loaded
oc logs pod/hcl-commerce-redis-master-0 -n redis-namespace | grep "Module.*loaded"

# Expected output:
# Module 'bf' loaded from /opt/bitnami/redis/lib/redis/modules/redisbloom.so
# Module 'search' loaded from /opt/bitnami/redis/lib/redis/modules/redisearch.so
# Module 'ReJSON' loaded from /opt/bitnami/redis/lib/redis/modules/rejson.so
# Module 'timeseries' loaded from /opt/bitnami/redis/lib/redis/modules/redistimeseries.so
```

## Testing Modules

Connect to Redis and test each module:

```bash
# Connect to Redis CLI
oc exec -it pod/hcl-commerce-redis-master-0 -n redis-namespace -- redis-cli

# Test RedisBloom
BF.ADD mybloom item1
BF.EXISTS mybloom item1

# Test RediSearch
FT.CREATE myindex ON HASH PREFIX 1 doc: SCHEMA title TEXT
HSET doc:1 title "Hello World"
FT.SEARCH myindex "hello"

# Test RedisJSON
JSON.SET myjson $ '{"name":"Redis","version":"8.4.2"}'
JSON.GET myjson

# Test RedisTimeSeries
TS.CREATE temperature RETENTION 86400000 LABELS sensor_id 1 location room
TS.ADD temperature * 23.5
TS.RANGE temperature - +
```

## Configuration Details

### Module Paths
Modules are installed at two locations for compatibility:
- `/opt/bitnami/redis/modules/` - Original build location
- `/opt/bitnami/redis/lib/redis/modules/` - Bitnami Helm chart expected location

### Bitnami 8.6 vs Redis 8.4.2

**Why this works:**
- Bitnami configuration files are version-agnostic
- Redis 8.4.2 and 8.6.3 have compatible configuration formats
- Bitnami helper scripts work with different Redis versions
- All modules are built from source for Redis 8.4.2

**What's used from Bitnami 8.6:**
- `redis-default.conf` - Production-ready configuration
- `entrypoint.sh`, `run.sh`, `postunpack.sh` - Container lifecycle scripts
- Directory structure under `/opt/bitnami`

**What's built for Redis 8.4.2:**
- Redis server and CLI tools (version 8.4.2)
- All 4 modules compiled for Redis 8.4.2

### Important Notes

1. **Parameter Name**: Use `commonConfiguration:` (not `configuration:`) in values.yaml for Bitnami Helm chart
2. **Module Paths**: Must use `/opt/bitnami/redis/lib/redis/modules/` prefix in loadmodule directives
3. **Image Size**: Final image is ~470 MB with all modules
4. **Security**: All system packages updated, secure Go version for utilities
5. **Bitnami Compatibility**: When Bitnami releases 8.4.2, consider updating to use official resources

## Troubleshooting

### Modules Not Loading

**Symptom**: Only 2 modules (redisearch, rejson) load instead of all 4

**Solution**: Ensure values.yaml uses `commonConfiguration:` parameter with all 4 loadmodule directives:

```yaml
commonConfiguration: |-
  loadmodule /opt/bitnami/redis/lib/redis/modules/redisbloom.so
  loadmodule /opt/bitnami/redis/lib/redis/modules/redisearch.so
  loadmodule /opt/bitnami/redis/lib/redis/modules/rejson.so
  loadmodule /opt/bitnami/redis/lib/redis/modules/redistimeseries.so
```

### Pod CrashLoopBackOff

**Check logs**:
```bash
oc logs pod/hcl-commerce-redis-master-0 -n redis-namespace
```

**Common causes**:
- Missing module files
- Incorrect module paths
- Insufficient permissions (check SCC)
- Bitnami script compatibility issues

### Build Failures

**ppc64le specific issues**:
- Ensure Rust toolchain patches are applied
- Verify Power10 CPU detection logic
- Check module Makefile modifications

**Bitnami download issues**:
- Verify Bitnami 8.6.3 tarball is accessible
- Check extracted directory name (no `-0-` in path)

## Architecture-Specific Fixes

### Rust Support for ppc64le
The build includes patches to add ppc64le support to Redis module build system:
- `modules/Makefile` - Rust installer detection
- `modules/common.mk` - Architecture mapping

### VectorSimilarity
Custom CPU features detection for ppc64le in RediSearch's VectorSimilarity component.

### RedisSearch Type Fixes
- FieldMask type corrections for ppc64le
- Duplicate constant removal
- Type casting fixes

## Performance

### Power10 Optimizations
When running on Power10 CPUs, the build automatically applies:
- `-mcpu=power10` compiler flag
- `-mtune=power10` optimization


All tests passed without errors, confirming:
- ✅ Redis 8.4.2 builds successfully
- ✅ All 4 modules compile and load
- ✅ ppc64le-specific patches work correctly
- ✅ Bitnami 8.6 configuration compatible with Redis 8.4.2

