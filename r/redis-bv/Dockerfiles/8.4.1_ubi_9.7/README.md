# Redis 8.4.1 with Modules for ppc64le (Power Architecture)

This repository contains the build configuration for Redis 8.4.1 with four essential modules compiled for ppc64le architecture and deployed on OpenShift.

## Overview

Custom Redis 8.4.1 image with the following modules:
- **RedisBloom** (v8.4.2) - Probabilistic data structures
- **RediSearch** (v8.4.5) - Full-text search and indexing
- **RedisJSON** (v8.4.2) - Native JSON data type
- **RedisTimeSeries** (v8.4.7) - Time-series data structures

## Architecture

- **Target Platform**: ppc64le (IBM POWER)
- **Base Image**: Red Hat UBI 9.7
- **Redis Version**: 8.4.1
- **Deployment**: OpenShift with Bitnami Helm Chart v24.1.8

## Files

### Dockerfile
Multi-stage build that:
1. Builds secure utilities (gosu, wait-for-port) with Go 1.26.2
2. Compiles Redis 8.4.1 from source with all 4 modules
3. Creates final image with runtime dependencies only

**Key Features:**
- Fixes for ppc64le architecture compatibility
- Power10 CPU optimizations (when available)
- Security updates for all dependencies
- Module path compatibility with Bitnami Helm chart

### values.yaml
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
  tag: 8.4.1

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

### redis-8.4.1-ppc64le-fixed.patch
Patch file containing fixes for:
- Rust toolchain support for ppc64le
- Module build system compatibility
- VectorSimilarity CPU features detection

## Building the Image

```bash
# Build the image
podman build -t redis-modules:8.4.1 -f Dockerfile .

# Tag for OpenShift registry
podman tag redis-modules:8.4.1 image-registry.openshift-image-registry.svc:5000/your-namespace/bit-redis:8.4.1

# Push to OpenShift
podman push image-registry.openshift-image-registry.svc:5000/your-namespace/bit-redis:8.4.1
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
JSON.SET myjson $ '{"name":"Redis","version":"8.4.1"}'
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

### Important Notes

1. **Parameter Name**: Use `commonConfiguration:` (not `configuration:`) in values.yaml for Bitnami Helm chart
2. **Module Paths**: Must use `/opt/bitnami/redis/lib/redis/modules/` prefix in loadmodule directives
3. **Image Size**: Final image is ~470 MB with all modules
4. **Security**: All system packages updated, secure Go version for utilities

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

### Build Failures

**ppc64le specific issues**:
- Ensure Rust toolchain patches are applied
- Verify Power10 CPU detection logic
- Check module Makefile modifications

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

### Resource Recommendations
- **CPU**: 500m request, 2000m limit
- **Memory**: 2Gi request, 4Gi limit
- **Storage**: Persistence disabled by default (configure as needed)

## Security

- Base image: Red Hat UBI 9.7 (regularly updated)
- Go 1.26.2 for utilities (fixes stdlib CVEs)
- All system packages updated during build
- Non-root user (UID 1001)
- Minimal runtime dependencies

## License

This configuration is provided as-is for building Redis with modules. Please refer to individual component licenses:
- Redis: BSD 3-Clause
- RedisBloom: Redis Source Available License
- RediSearch: Redis Source Available License
- RedisJSON: Redis Source Available License
- RedisTimeSeries: Redis Source Available License

## Support

For issues specific to this build configuration, please check:
1. Module compatibility with Redis 8.4.1
2. ppc64le architecture requirements
3. OpenShift/Kubernetes deployment constraints

## Version History

- **v8.4.1** - Initial release with all 4 modules for ppc64le
  - RedisBloom 8.4.2
  - RediSearch 8.4.5
  - RedisJSON 8.4.2
  - RedisTimeSeries 8.4.7