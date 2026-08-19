# Redis 8.8.0 with Modules for ppc64le (Power Architecture)

This repository contains the build configuration for Redis 8.8.0 with four essential modules compiled for ppc64le architecture and deployed on OpenShift.

## Overview

Custom Redis 8.8.0 image with the following modules:
- **RedisBloom** (v8.8.0) — Probabilistic data structures
- **RediSearch** (v8.8.0) — Full-text search and indexing
- **RedisJSON** (v8.8.0) — Native JSON data type
- **RedisTimeSeries** (v8.8.0) — Time-series data structures

## Architecture

- **Target Platform**: ppc64le (IBM POWER)
- **Base Image**: Red Hat UBI 9.8
- **Redis Version**: 8.8.0
- **Bitnami Containers Commit**: `731e897` (release 8.8.0-debian-12-r3)
- **Deployment**: OpenShift with Bitnami Helm Chart v24.1.8

## Files

| File | Description |
|---|---|
| `Dockerfile` | Multi-stage build for Redis 8.8.0 on ppc64le |
| `redis-bv_8.8.0.patch` | ppc64le fixes applied to the Redis source tree |

### Dockerfile

Three-stage build:
1. **`setupbuilder`** — Builds `gosu` and `wait-for-port` with a secure Go version; assembles the Bitnami `prebuildfs` and `rootfs` from the upstream containers repo
2. **`redisbuilder`** — Compiles Redis 8.8.0 from source with all 4 modules on UBI 9.8
3. **Final image** — UBI 9.8 runtime with only the necessary libraries; binaries and modules copied from builder stages

**Key features:**
- All ppc64le architecture fixes applied at source level
- SVS (ScalableVectorSearch) disabled — x86-only component, not applicable to ppc64le
- Power10 CPU optimisations applied automatically when detected
- Security updates for all system packages
- `gosu` and `wait-for-port` compiled from source with latest Go (fixes stdlib CVEs)
- Module paths compatible with Bitnami Helm chart

### redis-bv_8.8.0.patch

Applied to the Redis 8.8.0 source tree via `git apply`. Contains:
- `src/debug.c` — ppc64le register dump for crash diagnostics (`logRegisters`)
- `tests/support/util.tcl` — disables backtrace tests on ppc64le (unreliable on this arch)

### values.yaml (Helm)

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
  tag: 8.8.0

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

## Building the Image

```bash
# Both files must be in the same directory
podman build -t redis-ppc64le:8.8.0-bv -f Dockerfile .

# Tag for OpenShift internal registry
podman tag redis-ppc64le:8.8.0-bv \
  image-registry.openshift-image-registry.svc:5000/your-namespace/bit-redis:8.8.0

# Push to OpenShift
podman push \
  image-registry.openshift-image-registry.svc:5000/your-namespace/bit-redis:8.8.0
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
JSON.SET myjson $ '{"name":"Redis","version":"8.8.0"}'
JSON.GET myjson

# Test RedisTimeSeries
TS.CREATE temperature RETENTION 86400000 LABELS sensor_id 1 location room
TS.ADD temperature * 23.5
TS.RANGE temperature - +
```

## Configuration Details

### Module Paths
Modules are installed at two locations for compatibility:
- `/opt/bitnami/redis/modules/` — Build output location
- `/opt/bitnami/redis/lib/redis/modules/` — Bitnami Helm chart expected location

### Important Notes

1. **Parameter Name**: Use `commonConfiguration:` (not `configuration:`) in values.yaml
2. **Module Paths**: Must use `/opt/bitnami/redis/lib/redis/modules/` prefix in `loadmodule` directives
3. **Image Size**: Final image is approximately 500 MB with all modules
4. **Security**: All system packages updated; Go utilities built from source with latest Go

## Troubleshooting

### Modules Not Loading

**Symptom**: Only some modules (e.g. redisearch, rejson) load instead of all 4

**Solution**: Ensure `values.yaml` uses `commonConfiguration:` with all 4 `loadmodule` directives:

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
- Missing module `.so` files
- Incorrect module paths in `commonConfiguration`
- Insufficient permissions (check SCC assignment)

### Build Failures

**ppc64le-specific issues**:
- Confirm `lld` package is installed in `redisbuilder` stage (required by RediSearch Rust linker)
- Verify all inline Python source patches printed `OK` in build output
- Check that `IGNORE_MISSING_DEPS=1` is set for the first (priming) build pass

## Architecture-Specific Fixes

### Rust Support for ppc64le
- `modules/Makefile` — adds `ppc64le` case to Rust installer `case` block
- `modules/common.mk` — adds `ARCH_MAP_ppc64le := ppc64le` arch mapping

### SVS (ScalableVectorSearch) Disabled
SVS is x86-only (uses `yield` CPU instruction). Three files are patched:
- `build.sh` — passes `-DUSE_SVS=OFF` to cmake (sets `HAVE_SVS=0`)
- `index_factories/svs_factory.cpp` — entire file wrapped with `#if HAVE_SVS`
- `index_factories/tiered_factory.h` — `svs_tiered.h` include guarded
- `VecSim/vec_sim.cpp` — SVS-specific calls and include guarded

### VectorSimilarity CPU Features
`spaces.h` gains a `#elif defined(__powerpc64__)` branch returning `EmptyFeatures{}` so ppc64le does not fall through to the x86 code path.

### RediSearch Rust Type Fixes
On ppc64le `t_fieldMask = uint64_t` (not `uint128_t`):
- `ffi/src/lib.rs` — `RS_FIELDMASK_ALL: u128::MAX` → `u64::MAX`
- `ffi/build.rs` — `.blocklist_item("RS_FIELDMASK_ALL")` prevents bindgen emitting a conflicting `i32`
- `inverted_index/.../fields_only.rs` — `u128::read_as_varint` → `u64::read_as_varint`
- `inverted_index/.../index_result/` — explicit `as t_fieldMask` cast added

### RedisTimeSeries / RedisBloom
Architecture guards (`arm64v8`-only restrictions) removed from module `Makefile`s.

## Performance

### Power10 Optimisations
When running on Power10 CPUs the build automatically applies:
- `-mcpu=power10` compiler flag
- `-mtune=power10` optimisation

### Resource Recommendations
- **CPU**: 500m request, 2000m limit
- **Memory**: 2Gi request, 4Gi limit
- **Storage**: Persistence disabled by default (configure as needed)

## Security

- Base image: Red Hat UBI 9.8 (regularly updated)
- Go 1.26.5 for utilities (fixes stdlib CVEs)
- All system packages updated during build
- Non-root user (UID 1001)
- Minimal runtime dependencies in final image

## License

This configuration is provided as-is for building Redis with modules. Please refer to individual component licenses:
- Redis: BSD 3-Clause
- RedisBloom: Redis Source Available License
- RediSearch: Redis Source Available License
- RedisJSON: Redis Source Available License
- RedisTimeSeries: Redis Source Available License

## Support

For issues specific to this build configuration, please check:
1. Module compatibility with Redis 8.8.0
2. ppc64le architecture requirements
3. OpenShift/Kubernetes deployment constraints

## Version History

- **v8.8.0** — Redis 8.8.0 with all 4 modules for ppc64le on UBI 9.8
  - RedisBloom v8.8.0
  - RediSearch v8.8.0
  - RedisJSON v8.8.0
  - RedisTimeSeries v8.8.0
  - Base image upgraded from UBI 9.7 → UBI 9.8
  - Bitnami containers commit `731e897` (8.8.0-debian-12-r3)
  - SVS (ScalableVectorSearch) disabled — new in 8.8.0, x86-only
  - `svs_factory.cpp` guarded with `#if HAVE_SVS` — CMakeLists.txt compiles it unconditionally
  - `lld` linker added as build dependency
  - `index_result` patched as directory module (restructured in 8.8.0)
  - `ffi/build.rs` blocklist added for `RS_FIELDMASK_ALL`

- **v8.4.1** — Initial release with all 4 modules for ppc64le on UBI 9.7
  - RedisBloom v8.4.2
  - RediSearch v8.4.5
  - RedisJSON v8.4.2
  - RedisTimeSeries v8.4.7
