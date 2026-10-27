# Resource Advisor Architecture

## Problem Statement

Building native packages (protobuf, pytorch, llvm, arrow, etc.) with high parallelism causes OOM kills:
```
c++: fatal error: Killed signal terminated program cc1plus
```

This is the kernel OOM killer terminating compiler processes when memory is exhausted.

### Current Environment
- 128GB RAM total
- Up to 12 parallel container builds
- Each container uses `-j$(nproc)` (potentially 64+ cores)
- Memory-intensive C++ builds (protobuf, pytorch, llvm) can use 4-8GB+ per compiler process

### The Challenge
- Script-level hardcoding (`-j4`) doesn't scale
- Orchestrator doesn't know package memory requirements
- No feedback loop when OOM occurs
- "Killed" signal is silent failure - orchestrator sees exit code but not root cause

## Proposed Architecture

### Three-Level Control

```
┌─────────────────────────────────────────────────────────────┐
│  Level 1: Orchestrator                                      │
│  - Global view: total RAM, concurrent containers            │
│  - Reads build_info.json advisories                         │
│  - Calculates MAX_BUILD_JOBS per container                  │
│  - Can adjust based on current load                         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  Level 2: build_info.json (Advisory Metadata)               │
│  - Declares package resource characteristics                │
│  - Static, checked into repo                                │
│  - Orchestrator reads before scheduling                     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  Level 3: Template (base.sh / python.sh)                    │
│  - Respects MAX_BUILD_JOBS if set                           │
│  - Falls back to $(nproc) if not set                        │
│  - Simple, no hardcoded limits                              │
└─────────────────────────────────────────────────────────────┘
```

## build_info.json Schema Additions

```json
{
  "package_name": "protobuf",
  "version": "v25.3",
  "provides_artifact": "protobuf",

  "resource_advisory": {
    "memory_intensive": true,
    "suggested_jobs": 4,
    "peak_memory_gb": 8,
    "notes": "Large C++ files with heavy template usage"
  }
}
```

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `memory_intensive` | bool | Flag for orchestrator to apply limits |
| `suggested_jobs` | int | Recommended max parallel jobs |
| `peak_memory_gb` | int | Estimated peak memory per job |
| `notes` | string | Human-readable context |

### Known Memory-Intensive Packages

| Package | suggested_jobs | peak_memory_gb | Notes |
|---------|---------------|----------------|-------|
| protobuf | 4 | 8 | Heavy templates |
| pytorch | 4-8 | 6 | Huge codebase |
| llvm | 4 | 10 | Massive, many components |
| arrow | 4-6 | 6 | Complex build |
| grpc_cpp | 4 | 6 | Protobuf + more |
| boost | 4 | 4 | Many libraries |
| onnxruntime | 4 | 6 | ML framework |
| tensorflow | 4 | 8 | Bazel + huge |

## Template Implementation

### Simple Change
```bash
# In base.sh / python.sh
# Respect orchestrator guidance, fall back to nproc
BUILD_JOBS=${MAX_BUILD_JOBS:-$(nproc)}

# Use in build commands
cmake --build . --parallel "${BUILD_JOBS}"
make -j"${BUILD_JOBS}"
ninja -j"${BUILD_JOBS}"
```

### With Memory-Aware Fallback
```bash
# If orchestrator didn't set limit, be conservative for known hogs
if [[ -z "${MAX_BUILD_JOBS}" ]] && [[ "${MEMORY_INTENSIVE:-false}" == "true" ]]; then
    BUILD_JOBS=$(( $(nproc) > 4 ? 4 : $(nproc) ))
else
    BUILD_JOBS=${MAX_BUILD_JOBS:-$(nproc)}
fi
```

## Orchestrator Logic (Pseudocode)

### Static Scheduling (Simple)
```python
def calculate_jobs(build_info, concurrent_builds):
    available_ram_gb = get_available_ram_gb()
    ram_per_container = available_ram_gb / concurrent_builds

    if build_info.get('memory_intensive'):
        suggested = build_info.get('suggested_jobs', 4)
        peak_mem = build_info.get('peak_memory_gb', 4)

        # Don't exceed suggested, and ensure we have enough RAM
        max_from_ram = int(ram_per_container / peak_mem)
        return min(suggested, max(1, max_from_ram))
    else:
        return None  # Let container use $(nproc)
```

### Dynamic Adjustment (Advanced)
```python
def on_build_start(container, build_info):
    # Recalculate based on current state
    running = get_running_containers()
    available = get_available_ram_gb()

    jobs = calculate_jobs(build_info, len(running) + 1)
    container.env['MAX_BUILD_JOBS'] = jobs

def on_build_complete(container, exit_code, output):
    # Detect OOM for future adjustment
    if 'Killed signal terminated' in output:
        mark_package_memory_intensive(container.package)
        # Could auto-update build_info.json or separate learning file
```

## OOM Detection

The orchestrator should detect OOM kills:

```python
OOM_SIGNATURES = [
    'Killed signal terminated program',
    'fatal error: Killed',
    'out of memory',
    'Cannot allocate memory',
    'oom-kill',
]

def check_for_oom(output):
    return any(sig in output for sig in OOM_SIGNATURES)
```

### Response Options
1. **Log and alert** - Record which packages hit OOM
2. **Auto-retry with fewer jobs** - Reduce MAX_BUILD_JOBS and retry
3. **Update advisory** - Auto-populate resource_advisory in build_info.json
4. **Pause other builds** - If critically low on memory

## Implementation Phases

### Phase 1: Quick Fix (Current)
- Hardcode `-j4` in known memory hogs
- Gets builds passing now

### Phase 2: Template Support
- Add `BUILD_JOBS=${MAX_BUILD_JOBS:-$(nproc)}` to templates
- Scripts automatically respect orchestrator guidance

### Phase 3: build_info.json Advisory
- Add `resource_advisory` to known memory hogs
- Orchestrator reads and sets MAX_BUILD_JOBS

### Phase 4: OOM Detection
- Orchestrator parses output for OOM signatures
- Logs which packages failed due to memory
- Optional: auto-retry with reduced parallelism

### Phase 5: Learning (Optional)
- Track actual memory usage per package
- Auto-populate resource_advisory from observed data
- Optimize scheduling based on history

## Open Questions

1. **Granularity**: Per-package jobs or global limit?
2. **Retry Policy**: Auto-retry OOM failures with fewer jobs?
3. **Memory Monitoring**: Active monitoring vs. post-hoc detection?
4. **Container Limits**: Use cgroups memory limits instead/in addition?
5. **Build Order**: Schedule memory-intensive builds sequentially?

## Current Status

- **protobuf.sh**: Hardcoded `-j4` (temporary fix)
- **Templates**: Not yet updated for MAX_BUILD_JOBS
- **build_info.json**: Schema not yet extended
- **Orchestrator**: No resource awareness yet
