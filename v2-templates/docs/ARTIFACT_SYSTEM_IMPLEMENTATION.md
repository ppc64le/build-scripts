# Artifact System Implementation Notes

Technical implementation guide for the native dependency artifact system.
See `NATIVE_DEPENDENCIES.md` for the user-facing guide.

---

## Overview

The artifact system enables building complex packages like vllm by:
1. Breaking monolithic scripts into focused, reusable scripts
2. Declaring dependencies in `build_info.json` (already parsed by preprocessor)
3. Using topological sort to determine build order
4. Sharing artifacts across the build matrix via a global workspace

---

## Two-Stage Architecture

Dependencies are declared in **two places** for modularity:

### Stage 1: Preprocessor (build_info.json)

The preprocessor reads `build_info.json` to determine build order:

```json
{
  "package_name": "protobuf",
  "provides_artifact": "protobuf",
  "build_deps": ["abseil-cpp:20240116.2"],
  ...
}
```

| Field | Type | Description |
|-------|------|-------------|
| `provides_artifact` | string | Name of the artifact this script produces |
| `build_deps` | array | Dependencies in `name:version` format |

The preprocessor:
1. Performs topological sort to determine build order
2. Sets up the shared artifact workspace
3. Passes `ARTIFACT_WORKSPACE` environment variable to scripts

### Stage 2: Runtime (shell variables)

Scripts declare the same information as shell variables:

```bash
PROVIDES_ARTIFACT="protobuf"
BUILD_DEPS="abseil-cpp:20240116.2"
```

The template uses these to trigger artifact support:
```bash
# In templates/python.sh
if [[ -n "${BUILD_DEPS:-}" || -n "${PROVIDES_ARTIFACT:-}" ]]; then
    source "${SCRIPT_DIR}/lib/artifacts.sh"
fi
```

### Why Both?

This intentional duplication maintains **stage isolation**:
- Preprocessor stage doesn't need to parse bash
- Runtime stage doesn't need access to JSON metadata
- Each stage is self-contained and testable independently
- Execution engine acts as the bridge, setting `ARTIFACT_WORKSPACE`

---

## Template Changes

### New File: `templates/lib/artifacts.sh`

This file is auto-sourced when `BUILD_DEPS` or `PROVIDES_ARTIFACT` shell variables are set.

```bash
#!/bin/bash
# =============================================================================
# Artifact System Helper Functions
# Sourced automatically when BUILD_DEPS or PROVIDES_ARTIFACT is present
# =============================================================================

# ARTIFACT_WORKSPACE is set by the execution engine to a shared location
# that persists across builds in a run. Falls back to OUTPUT_DIR/artifacts
# for local testing.
: "${ARTIFACT_WORKSPACE:=${OUTPUT_DIR:-/tmp}/artifacts}"

# -----------------------------------------------------------------------------
# artifact_dir - Get path to artifact directory
# Usage: artifact_dir <name> [version]
# If version not specified, uses "default" or finds latest
# -----------------------------------------------------------------------------
artifact_dir() {
    local name="$1"
    local version="${2:-default}"
    echo "${ARTIFACT_WORKSPACE}/${name}/${version}"
}

# -----------------------------------------------------------------------------
# source_artifact - Source an artifact's environment
# Usage: source_artifact <name> [version]
# Returns: 0 if found and sourced, 1 if not found
# -----------------------------------------------------------------------------
source_artifact() {
    local name="$1"
    local version="${2:-}"
    local artifact_base="${ARTIFACT_WORKSPACE}/${name}"

    # If version specified, use it directly
    if [[ -n "$version" ]]; then
        local env_file="${artifact_base}/${version}/env.sh"
        if [[ -f "$env_file" ]]; then
            log_info "Sourcing ${name}:${version} from ${artifact_base}/${version}"
            source "$env_file"
            return 0
        fi
        log_error "Artifact not found: ${name}:${version}"
        return 1
    fi

    # No version specified - find any available version
    local latest_env=""
    for env_file in "${artifact_base}"/*/env.sh; do
        [[ -f "$env_file" ]] && latest_env="$env_file"
    done

    if [[ -n "$latest_env" ]]; then
        log_info "Sourcing ${name} from $(dirname "$latest_env")"
        source "$latest_env"
        return 0
    fi

    log_error "No artifact found for: ${name}"
    return 1
}

# -----------------------------------------------------------------------------
# generate_artifact_manifest - Create manifest.json for an artifact
# Usage: generate_artifact_manifest <dir> <name> <version> <url> <license_spdx> [deps...]
# -----------------------------------------------------------------------------
generate_artifact_manifest() {
    local artifact_dir="$1"
    local name="$2"
    local version="$3"
    local git_url="${4:-}"
    local license_spdx="${5:-UNKNOWN}"
    shift 5
    local depends_on=("$@")

    local manifest_file="${artifact_dir}/manifest.json"
    local git_sha=""

    # Try to get git sha
    if command -v git &>/dev/null; then
        git_sha=$(git rev-parse HEAD 2>/dev/null || echo "")
    fi

    # Build depends_on JSON array
    local deps_json="[]"
    if [[ ${#depends_on[@]} -gt 0 ]]; then
        deps_json=$(printf '%s\n' "${depends_on[@]}" | jq -R . | jq -s .)
    fi

    # Generate manifest
    cat > "${manifest_file}" << EOF
{
  "name": "${name}",
  "version": "${version}",
  "git_sha": "${git_sha}",
  "git_url": "${git_url}",
  "build_date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "build_host": "$(hostname -s 2>/dev/null || echo unknown)",
  "arch": "$(uname -m)",
  "license_spdx": "${license_spdx}",
  "license_files": ["LICENSE"],
  "depends_on": ${deps_json}
}
EOF
    log_info "Generated manifest: ${manifest_file}"
}

# -----------------------------------------------------------------------------
# collect_dependency_licenses - Gather licenses from all artifacts
# Usage: collect_dependency_licenses <output_dir>
# -----------------------------------------------------------------------------
collect_dependency_licenses() {
    local output_dir="${1:-.}"
    local summary_file="${output_dir}/THIRD_PARTY_LICENSES.txt"
    local artifacts_dir="${ARTIFACT_WORKSPACE}"

    mkdir -p "${output_dir}"

    echo "# Third-Party Licenses" > "${summary_file}"
    echo "" >> "${summary_file}"
    echo "Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "${summary_file}"
    echo "" >> "${summary_file}"

    # Check if jq is available
    if ! command -v jq &>/dev/null; then
        log_warn "jq not available, using fallback license collection"
        _collect_licenses_fallback "${output_dir}" "${summary_file}" "${artifacts_dir}"
        return
    fi

    local found_any=false

    # Iterate through all artifact manifests
    for manifest in "${artifacts_dir}"/*/*/manifest.json; do
        [[ -f "$manifest" ]] || continue
        found_any=true

        local artifact_path=$(dirname "$manifest")
        local name=$(jq -r '.name // "unknown"' "$manifest")
        local version=$(jq -r '.version // "unknown"' "$manifest")
        local spdx=$(jq -r '.license_spdx // "UNKNOWN"' "$manifest")
        local git_url=$(jq -r '.git_url // ""' "$manifest")

        echo "## ${name} ${version}" >> "${summary_file}"
        echo "" >> "${summary_file}"
        echo "- SPDX License: ${spdx}" >> "${summary_file}"
        [[ -n "$git_url" ]] && echo "- Source: ${git_url}" >> "${summary_file}"
        echo "" >> "${summary_file}"

        # Copy license files
        local license_files=$(jq -r '.license_files[]? // empty' "$manifest" 2>/dev/null)
        for license_file in $license_files; do
            local src="${artifact_path}/${license_file}"
            if [[ -f "$src" ]]; then
                local dest="${output_dir}/${name}-${spdx}.txt"
                cp "$src" "$dest"
                echo "License file: ${name}-${spdx}.txt" >> "${summary_file}"
            fi
        done

        echo "" >> "${summary_file}"
        echo "---" >> "${summary_file}"
        echo "" >> "${summary_file}"
    done

    if [[ "$found_any" == "false" ]]; then
        echo "No third-party dependency artifacts found." >> "${summary_file}"
    fi

    log_info "Collected licenses to ${output_dir}"
}

# Fallback without jq
_collect_licenses_fallback() {
    local output_dir="$1"
    local summary_file="$2"
    local artifacts_dir="$3"

    for artifact_path in "${artifacts_dir}"/*/*/; do
        [[ -d "$artifact_path" ]] || continue
        local name=$(basename "$(dirname "$artifact_path")")
        local version=$(basename "$artifact_path")

        for license_file in "${artifact_path}"/LICENSE*; do
            if [[ -f "$license_file" ]]; then
                cp "$license_file" "${output_dir}/${name}-${version}-LICENSE.txt"
                echo "## ${name} ${version}" >> "${summary_file}"
                echo "" >> "${summary_file}"
            fi
        done
    done
}
```

### Changes to `templates/python.sh`

Add auto-detection and sourcing of artifacts.sh:

```bash
# Near the top, after sourcing common.sh:

# Auto-source artifacts.sh if BUILD_DEPS or PROVIDES_ARTIFACT is declared
if grep -qE '^#\s*(BUILD_DEPS|PROVIDES_ARTIFACT)\s*=' "${BASH_SOURCE[1]}" 2>/dev/null; then
    source "${SCRIPT_DIR}/lib/artifacts.sh"
fi
```

### Changes to `templates/lib/common.sh`

Add OUTPUT_DIR handling:

```bash
# Ensure OUTPUT_DIR is set
export OUTPUT_DIR="${OUTPUT_DIR:-/output}"

# Create artifacts directory
mkdir -p "${OUTPUT_DIR}/artifacts" 2>/dev/null || true
```

---

## Preprocessor Requirements

### Reading from build_info.json

The preprocessor already parses `build_info.json` - just add extraction of the new fields:

```python
import json
from pathlib import Path
from dataclasses import dataclass, field
from typing import Optional

@dataclass
class PackageInfo:
    path: Path
    package_name: str
    provides: Optional[str] = None
    depends: list[tuple[str, str]] = field(default_factory=list)  # [(name, version), ...]

def parse_build_info(build_info_path: Path) -> PackageInfo:
    """Parse a build_info.json for dependency declarations."""
    with open(build_info_path) as f:
        info = json.load(f)

    package_name = info.get("package_name", build_info_path.parent.name)
    provides = info.get("provides_artifact")

    # Parse build_deps: ["protobuf:v25.3", "openblas:v0.3.29"]
    deps = []
    for dep in info.get("build_deps", []):
        if ':' in dep:
            name, version = dep.split(':', 1)
        else:
            name, version = dep, 'latest'
        deps.append((name, version))

    return PackageInfo(
        path=build_info_path.parent,
        package_name=package_name,
        provides=provides,
        depends=deps
    )

def load_all_packages(base_dir: Path) -> list[PackageInfo]:
    """Load all packages from build_info.json files."""
    packages = []
    for build_info in base_dir.glob("*/*/build_info.json"):
        packages.append(parse_build_info(build_info))
    return packages
```

### Building the Dependency Graph

```python
from graphlib import TopologicalSorter, CycleError

def build_dependency_graph(scripts: list[PackageInfo]) -> dict[str, set[str]]:
    """
    Build dependency graph from script info.

    Returns dict mapping artifact_name -> set of dependencies
    """
    # Map artifact names to scripts that provide them
    providers: dict[str, PackageInfo] = {}
    for script in scripts:
        if script.provides:
            providers[script.provides] = script

    # Build graph
    graph: dict[str, set[str]] = {}

    for script in scripts:
        # Use provides name if available, else package name
        node_name = script.provides or script.package_name

        # Dependencies are just the artifact names
        graph[node_name] = {dep_name for dep_name, _ in script.depends}

    return graph

def compute_build_order(scripts: list[PackageInfo]) -> list[PackageInfo]:
    """
    Compute build order using topological sort.

    Returns scripts in order they should be built.
    """
    graph = build_dependency_graph(scripts)

    try:
        ts = TopologicalSorter(graph)
        order = list(ts.static_order())
    except CycleError as e:
        raise ValueError(f"Circular dependency detected: {e}")

    # Map back to PackageInfo objects
    name_to_script = {
        (s.provides or s.package_name): s
        for s in scripts
    }

    return [name_to_script[name] for name in order if name in name_to_script]
```

### Tier Detection

```python
def get_tiers(scripts: list[PackageInfo]) -> dict[int, list[PackageInfo]]:
    """
    Group scripts by dependency tier.

    Tier 0: No dependencies (roots)
    Tier N: Depends only on Tier 0..N-1
    """
    graph = build_dependency_graph(scripts)
    name_to_script = {(s.provides or s.package_name): s for s in scripts}

    tiers: dict[int, list[PackageInfo]] = {}
    assigned: dict[str, int] = {}

    def get_tier(name: str) -> int:
        if name in assigned:
            return assigned[name]

        deps = graph.get(name, set())
        if not deps:
            tier = 0
        else:
            tier = max(get_tier(d) for d in deps) + 1

        assigned[name] = tier
        return tier

    for name in graph:
        tier = get_tier(name)
        if tier not in tiers:
            tiers[tier] = []
        if name in name_to_script:
            tiers[tier].append(name_to_script[name])

    return tiers
```

### Lockfile Generation

```python
import json
from datetime import datetime, timezone

def generate_lockfile(scripts: list[PackageInfo], resolved_versions: dict[str, str]) -> dict:
    """
    Generate lockfile for reproducible builds.

    resolved_versions: maps artifact names to resolved versions
    """
    return {
        "generated": datetime.now(timezone.utc).isoformat(),
        "artifacts": {
            (s.provides or s.package_name): {
                "script": str(s.path),
                "provides": s.provides,
                "version": resolved_versions.get(s.provides or s.package_name),
                "depends_on": [
                    f"{name}:{resolved_versions.get(name, version)}"
                    for name, version in s.depends
                ]
            }
            for s in scripts
            if s.provides or s.depends
        }
    }
```

---

## Execution Engine Integration

### Global Artifact Workspace

The artifact directory should be global to the build run:

```python
# In execution engine
import os

class BuildContext:
    def __init__(self, output_dir: str = "/output"):
        self.output_dir = output_dir
        self.artifact_dir = os.path.join(output_dir, "artifacts")
        os.makedirs(self.artifact_dir, exist_ok=True)

    def get_artifact_path(self, name: str, version: str) -> str:
        return os.path.join(self.artifact_dir, name, version)

    def artifact_exists(self, name: str, version: str) -> bool:
        path = self.get_artifact_path(name, version)
        return os.path.exists(os.path.join(path, "env.sh"))
```

### Build Phases

```python
async def run_build(scripts: list[PackageInfo], context: BuildContext):
    """Execute builds in dependency order."""

    # Phase 1: Parse and resolve
    build_order = compute_build_order(scripts)
    tiers = get_tiers(scripts)

    print(f"Build order: {len(build_order)} scripts in {len(tiers)} tiers")

    # Phase 2: Build artifacts (in order)
    for script in build_order:
        # Check if already built
        if script.provides:
            version = get_version(script)  # From PACKAGE_VERSION
            if context.artifact_exists(script.provides, version):
                print(f"Skipping {script.provides}:{version} (already built)")
                continue

        # Build
        print(f"Building {script.path}...")
        await run_script(script, context)

    # Phase 3: Generate lockfile
    lockfile = generate_lockfile(scripts, resolved_versions)
    write_lockfile(lockfile, context.output_dir)
```

### Parallel Execution Within Tiers

Scripts within the same tier have no dependencies on each other:

```python
import asyncio

async def run_build_parallel(scripts: list[PackageInfo], context: BuildContext):
    """Execute builds with parallelism within tiers."""

    tiers = get_tiers(scripts)

    for tier_num in sorted(tiers.keys()):
        tier_scripts = tiers[tier_num]
        print(f"=== Tier {tier_num}: {len(tier_scripts)} scripts ===")

        # Run all scripts in this tier in parallel
        tasks = [run_script(s, context) for s in tier_scripts]
        await asyncio.gather(*tasks)
```

---

## New Scripts to Create

### Tier 0 Scripts (No Dependencies)

These are the foundation - build first, no `BUILD_DEPS`:

| Script | PROVIDES_ARTIFACT | Priority |
|--------|-------------------|----------|
| `o/openblas/openblas.sh` | openblas | High (pytorch needs) |
| `a/abseil-cpp/abseil-cpp.sh` | abseil-cpp | High (protobuf needs) |
| `l/libvpx/libvpx.sh` | libvpx | Medium (ffmpeg needs) |
| `l/lame/lame.sh` | lame | Medium (ffmpeg needs) |
| `o/opus/opus.sh` | opus | Medium (ffmpeg needs) |
| `z/zstd/zstd.sh` | zstd | Medium (arrow needs) |
| `s/snappy/snappy.sh` | snappy | Medium (arrow needs) |
| `r/re2/re2.sh` | re2 | Medium (grpc needs) |
| `c/c-ares/c-ares.sh` | c-ares | Medium (grpc needs) |
| `h/hwloc/hwloc.sh` | hwloc | Low (onetbb needs) |

### Tier 1 Scripts

| Script | PROVIDES_ARTIFACT | BUILD_DEPS |
|--------|-------------------|------------|
| `p/protobuf/protobuf.sh` | protobuf | abseil-cpp |
| `f/ffmpeg/ffmpeg.sh` | ffmpeg | libvpx, lame, opus |
| `l/llvm/llvm.sh` | llvm | (none - or cmake) |
| `h/hdf5/hdf5.sh` | hdf5 | (none) |
| `b/boost/boost.sh` | boost | (none) |

### Tier 2 Scripts

| Script | PROVIDES_ARTIFACT | BUILD_DEPS |
|--------|-------------------|------------|
| `p/pytorch/pytorch.sh` | pytorch | openblas, protobuf |
| `g/grpc/grpc.sh` | grpc | protobuf, c-ares, re2, abseil-cpp |
| `l/llvmlite/llvmlite.sh` | llvmlite | llvm |
| `a/arrow/arrow.sh` | arrow | protobuf, grpc, boost, snappy, zstd |

### Tier 3+ Scripts

| Script | BUILD_DEPS |
|--------|------------|
| `t/torchvision/torchvision.sh` | pytorch |
| `t/torchaudio/torchaudio.sh` | pytorch |
| `n/numba/numba.sh` | llvmlite |
| `p/pyarrow/pyarrow.sh` | arrow |
| `v/vllm/vllm.sh` | pytorch, torchvision, pyarrow, numba |

---

## Example: Creating openblas (Tier 0)

### o/openblas/build_info.json

```json
{
  "maintainer": "ibm",
  "package_name": "OpenBLAS",
  "github_url": "https://github.com/OpenMathLib/OpenBLAS",
  "version": "v0.3.29",
  "default_branch": "develop",
  "build_script": "openblas.sh",
  "wheel_build": false,
  "provides_artifact": "openblas"
}
```

### o/openblas/openblas.sh

```bash
#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : OpenBLAS
# Version       : v0.3.29
# Source repo   : https://github.com/OpenMathLib/OpenBLAS
# Tested on     : UBI:9.3
# Language      : C, Fortran
#
# Notes:
#   - Tier 0 artifact provider (no dependencies)
#   - Built with POWER9 target for ppc64le optimization
#   - Provides libopenblas.so for numpy, scipy, pytorch, etc.
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PACKAGE_NAME="OpenBLAS"
PACKAGE_VERSION="${1:-v0.3.29}"
PACKAGE_URL="https://github.com/OpenMathLib/OpenBLAS"

RH_DEP_PKGS="git gcc gcc-c++ gcc-gfortran make"
DEB_DEP_PKGS="git gcc g++ gfortran make"
SLES_DEP_PKGS="git gcc gcc-c++ gcc-fortran make"

custom_install() {
    local ARTIFACT_DIR="$(artifact_dir openblas ${PACKAGE_VERSION})"

    # Check if already built
    if [[ -f "${ARTIFACT_DIR}/env.sh" ]]; then
        log_info "OpenBLAS artifact already exists"
        return 0
    fi

    mkdir -p "${ARTIFACT_DIR}"

    # Build options for POWER9
    declare -a build_opts=(
        "USE_OPENMP=1"
        "BINARY=64"
        "DYNAMIC_ARCH=1"
        "TARGET=POWER9"
        "INTERFACE64=0"
        "NO_LAPACK=0"
        "USE_THREAD=1"
        "NUM_THREADS=8"
        "NO_AFFINITY=1"
    )

    log_info "Building OpenBLAS with options: ${build_opts[*]}"

    make "${build_opts[@]}" -j$(nproc)
    make install PREFIX="${ARTIFACT_DIR}" "${build_opts[@]}"

    # Copy license
    cp LICENSE "${ARTIFACT_DIR}/"

    # Generate env.sh
    cat > "${ARTIFACT_DIR}/env.sh" << EOF
export OPENBLAS_PREFIX="${ARTIFACT_DIR}"
export LD_LIBRARY_PATH="${ARTIFACT_DIR}/lib:\${LD_LIBRARY_PATH:-}"
export PKG_CONFIG_PATH="${ARTIFACT_DIR}/lib/pkgconfig:\${PKG_CONFIG_PATH:-}"
export CMAKE_PREFIX_PATH="${ARTIFACT_DIR}:\${CMAKE_PREFIX_PATH:-}"
EOF

    # Generate manifest
    generate_artifact_manifest "${ARTIFACT_DIR}" \
        "openblas" "${PACKAGE_VERSION}" \
        "${PACKAGE_URL}" "BSD-3-Clause"

    log_info "OpenBLAS installed to ${ARTIFACT_DIR}"
}

# No tests for C library artifact
SKIP_TESTS=true

source "${SCRIPT_DIR}/../../templates/python.sh"
```

---

## Migration Checklist

### Phase 1: Schema and Template Updates
- [ ] Add `provides_artifact` and `build_deps` to `templates/build_info_template.json` ✓
- [ ] Create `templates/lib/artifacts.sh`
- [ ] Update `templates/python.sh` to auto-source artifacts.sh
- [ ] Update `templates/lib/common.sh` for OUTPUT_DIR
- [ ] Add `jq` to container base image (for manifest parsing)

### Phase 2: Update parse_build_info.py
- [ ] Add extraction of `provides_artifact` field
- [ ] Add extraction of `build_deps` array
- [ ] Add topological sort using graphlib
- [ ] Add tier detection

### Phase 3: Create Tier 0 build_info.json + Scripts
- [ ] `o/openblas/` - add `"provides_artifact": "openblas"`
- [ ] `a/abseil-cpp/` - add `"provides_artifact": "abseil-cpp"`
- [ ] `l/libvpx/` - add `"provides_artifact": "libvpx"`
- [ ] `l/lame/` - add `"provides_artifact": "lame"`
- [ ] `o/opus/` - add `"provides_artifact": "opus"`
- [ ] `z/zstd/` - add `"provides_artifact": "zstd"`
- [ ] `s/snappy/` - add `"provides_artifact": "snappy"`

### Phase 4: Create Tier 1 build_info.json + Scripts
- [ ] `p/protobuf/` - `"provides_artifact": "protobuf"`, `"build_deps": ["abseil-cpp:..."]`
- [ ] `f/ffmpeg/` - `"provides_artifact": "ffmpeg"`, `"build_deps": [...]`
- [ ] `l/llvm/` - `"provides_artifact": "llvm"`
- [ ] `h/hdf5/` - `"provides_artifact": "hdf5"`

### Phase 5: Create Tier 2 build_info.json + Scripts
- [ ] `p/pytorch/` - `"provides_artifact": "pytorch"`, `"build_deps": ["openblas:...", "protobuf:..."]`
- [ ] `g/grpc/` - `"provides_artifact": "grpc"`, `"build_deps": [...]`
- [ ] `l/llvmlite/` - `"provides_artifact": "llvmlite"`, `"build_deps": ["llvm:..."]`
- [ ] `a/arrow/` - `"provides_artifact": "arrow"`, `"build_deps": [...]`

### Phase 6: Update Consumer build_info.json
- [ ] Add `"build_deps": [...]` to existing packages (onnx, h5py, etc.)
- [ ] Update scripts to use `source_artifact` calls

### Phase 7: Execution Engine Updates
- [ ] Global artifact workspace
- [ ] Tier-based parallel execution
- [ ] Artifact caching
- [ ] Lockfile generation
