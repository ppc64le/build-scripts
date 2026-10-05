# Building Python Packages with Native Dependencies

This guide covers how to build Python packages that require C/C++ libraries
compiled from source. Most packages don't need this - only about 15% of our
catalog requires native dependency management.

## When Do You Need This?

**You DON'T need this guide if:**
- Your package is pure Python
- Your package uses Cython but only needs `pip install cython` in `pre_build`
- System packages (`RH_DEP_PKGS`) provide what you need (e.g., `openssl-devel`)

**You DO need this guide if:**
- PyPI wheels don't exist for ppc64le
- The package requires a specific version of a C library not in system repos
- You see errors like "libprotobuf.so not found" or "HDF5 version mismatch"

---

## Core Concepts

### Two-Stage Declaration

Dependencies are declared in **two places** - this is intentional for modularity:

1. **build_info.json** - Read by preprocessor for build ordering
2. **Shell variables** - Used by script at runtime

This separation ensures each stage is self-contained. The preprocessor doesn't
need to parse bash, and scripts don't need access to JSON metadata at runtime.

#### build_info.json (preprocessor stage)

```json
{
  "package_name": "pytorch",
  "provides_artifact": "pytorch",
  "build_deps": ["openblas:v0.3.29", "protobuf:v4.25.3"],
  ...
}
```

The preprocessor uses this to:
- Build the dependency graph
- Perform topological sort for build order
- Set up shared artifact workspace
- Pass `ARTIFACT_WORKSPACE` environment variable to scripts

#### Shell variables (runtime stage)

```bash
# In the script itself
PROVIDES_ARTIFACT="pytorch"
BUILD_DEPS="openblas:v0.3.29 protobuf:v4.25.3"
```

The template uses these to:
- Decide whether to source `lib/artifacts.sh`
- Know what artifacts to source/create

### Dependency Tiers

Dependencies form a natural hierarchy:

```
Tier 0: No dependencies (roots)
├── openblas, abseil-cpp, libvpx, lame, opus, zstd, snappy, etc.

Tier 1: Depends on Tier 0
├── protobuf (← abseil-cpp)
├── ffmpeg (← libvpx, lame, opus)
├── LLVM (← cmake)

Tier 2: Depends on Tier 1
├── pytorch (← openblas, protobuf)
├── grpc (← protobuf, c-ares, re2, abseil-cpp)
├── arrow (← protobuf, grpc, boost, thrift, snappy, zstd)

Tier 3: Depends on Tier 2
├── pyarrow (← arrow)
├── numba (← llvmlite ← LLVM)
├── torchvision (← pytorch)

Tier 4: Final packages
└── vllm (← pytorch, pyarrow, numba, torchvision, ...)
```

### Global Artifact Workspace

Artifacts are shared across the entire build matrix (package versions × Python versions).
The execution engine sets `ARTIFACT_WORKSPACE` to a shared, persistent location:

```
${ARTIFACT_WORKSPACE}/             # Set by execution engine, shared across builds
├── openblas/
│   └── v0.3.29/                   # Version-specific
│       ├── env.sh
│       ├── manifest.json
│       ├── LICENSE
│       └── lib/, include/, bin/
├── protobuf/
│   └── v4.25.3/
│       └── ...
├── pytorch/
│   └── v2.6.0/
│       └── ...
└── ...
```

This means:
- Build `openblas:v0.3.29` once, reuse for pytorch, scipy, numpy, etc.
- Build `pytorch:v2.6.0` once, reuse for torchvision, torchaudio, vllm
- Different versions can coexist: `protobuf/v4.25.3/` and `protobuf/v25.3/`

---

## Script Structure

### Provider Script (C/C++ Library)

**build_info.json** (for preprocessor):

```json
{
  "package_name": "protobuf",
  "github_url": "https://github.com/protocolbuffers/protobuf",
  "version": "v4.25.3",
  "provides_artifact": "protobuf",
  "build_deps": ["abseil-cpp:20240116.2"],
  "build_script": "protobuf.sh",
  ...
}
```

**protobuf.sh** (runtime):

```bash
#!/bin/bash -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PACKAGE_NAME="protobuf"
PACKAGE_VERSION="${1:-v4.25.3}"
PACKAGE_URL="https://github.com/protocolbuffers/protobuf"

# Runtime declarations - triggers lib/artifacts.sh sourcing
PROVIDES_ARTIFACT="protobuf"
BUILD_DEPS="abseil-cpp:20240116.2"

RH_DEP_PKGS="git gcc gcc-c++ cmake ninja-build"

custom_install() {
    local ARTIFACT_DIR="$(artifact_dir protobuf ${PACKAGE_VERSION})"

    # Check if already built
    if [[ -f "${ARTIFACT_DIR}/env.sh" ]]; then
        log_info "Artifact already exists at ${ARTIFACT_DIR}"
        return 0
    fi

    # Source dependencies
    source_artifact abseil-cpp || return 1

    # Build protobuf...
    cmake -B build \
        -DCMAKE_INSTALL_PREFIX="${ARTIFACT_DIR}" \
        -DCMAKE_BUILD_TYPE=Release \
        ...

    cmake --build build -j$(nproc)
    cmake --install build

    # Copy license
    cp LICENSE "${ARTIFACT_DIR}/"

    # Generate env.sh
    cat > "${ARTIFACT_DIR}/env.sh" << EOF
export CMAKE_PREFIX_PATH="${ARTIFACT_DIR}:\${CMAKE_PREFIX_PATH:-}"
export LD_LIBRARY_PATH="${ARTIFACT_DIR}/lib:\${LD_LIBRARY_PATH:-}"
export PATH="${ARTIFACT_DIR}/bin:\${PATH}"
export PROTOC="${ARTIFACT_DIR}/bin/protoc"
EOF

    # Generate manifest
    generate_artifact_manifest "${ARTIFACT_DIR}" \
        "protobuf" "${PACKAGE_VERSION}" \
        "${PACKAGE_URL}" "BSD-3-Clause"
}

source "${SCRIPT_DIR}/../../templates/python.sh"
```

### Consumer Script (Python Package)

**build_info.json** (for preprocessor):

```json
{
  "package_name": "onnx",
  "github_url": "https://github.com/onnx/onnx",
  "version": "v1.17.0",
  "build_deps": ["protobuf:v25.3"],
  "build_script": "onnx.sh",
  ...
}
```

**onnx.sh** (runtime):

```bash
#!/bin/bash -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PACKAGE_NAME="onnx"
PACKAGE_VERSION="${1:-v1.17.0}"
PACKAGE_URL="https://github.com/onnx/onnx"

# Runtime declaration - triggers lib/artifacts.sh sourcing
BUILD_DEPS="protobuf:v25.3"

RH_DEP_PKGS="git gcc gcc-c++ python3-devel python3-pip cmake"

pre_build() {
    # Source required artifacts
    source_artifact protobuf || {
        log_error "protobuf artifact not found - run protobuf.sh first"
        return 1
    }

    pip install numpy pybind11
}

source "${SCRIPT_DIR}/../../templates/python.sh"
```

---

## Dependency Resolution

### How tsort Works

The preprocessor reads `build_info.json` files (which it already parses) and
builds a dependency graph:

```python
# Extracted from build_info.json files:
def load_artifacts(package_dirs):
    artifacts = {}
    for pkg_dir in package_dirs:
        info = json.load(open(f"{pkg_dir}/build_info.json"))
        artifacts[info["package_name"]] = {
            "provides": info.get("provides_artifact"),
            "depends": [dep.split(":")[0] for dep in info.get("build_deps", [])]
        }
    return artifacts

# Result:
artifacts = {
    "openblas":    {"provides": "openblas",    "depends": []},
    "abseil-cpp":  {"provides": "abseil-cpp",  "depends": []},
    "protobuf":    {"provides": "protobuf",    "depends": ["abseil-cpp"]},
    "pytorch":     {"provides": "pytorch",     "depends": ["openblas", "protobuf"]},
    "onnx":        {"provides": None,          "depends": ["protobuf"]},
    "vllm":        {"provides": None,          "depends": ["pytorch", "pyarrow", "numba"]},
}

# Topological sort produces build order:
from graphlib import TopologicalSorter

ts = TopologicalSorter()
for name, info in artifacts.items():
    ts.add(name, *info["depends"])

build_order = list(ts.static_order())
# ["openblas", "abseil-cpp", "protobuf", "pytorch", "onnx", ...]
```

### Tier 0 Detection

Scripts with `PROVIDES_ARTIFACT` but no `BUILD_DEPS` are automatically Tier 0 (roots):

```python
def get_tier_0_packages(scripts):
    """Find packages with no dependencies (graph roots)"""
    return [
        name for name, info in scripts.items()
        if info["provides"] and not info["depends"]
    ]
```

### Version Resolution

```bash
# Explicit version
# BUILD_DEPS="protobuf:v4.25.3"

# Latest available (resolved at build time)
# BUILD_DEPS="protobuf:latest"

# Version recorded in lockfile for reproducibility
```

---

## Artifact Directory Structure

```
${ARTIFACT_WORKSPACE}/
├── protobuf/
│   └── v4.25.3/
│       ├── env.sh           # Environment setup
│       ├── manifest.json    # Metadata + license info
│       ├── LICENSE          # Original license file
│       ├── bin/
│       │   └── protoc
│       ├── lib/
│       │   ├── libprotobuf.so
│       │   └── libprotobuf.a
│       └── include/
│           └── google/
│               └── protobuf/
└── pytorch/
    └── v2.6.0/
        ├── env.sh
        ├── manifest.json
        ├── LICENSE
        └── lib/
            └── python3.12/
                └── site-packages/
                    └── torch/
```

### env.sh

Sets up environment for dependents. Uses absolute paths based on where the
artifact was installed:

```bash
# protobuf/v4.25.3/env.sh
# Paths are absolute, set at install time
export CMAKE_PREFIX_PATH="/shared/artifacts/protobuf/v4.25.3:${CMAKE_PREFIX_PATH:-}"
export LD_LIBRARY_PATH="/shared/artifacts/protobuf/v4.25.3/lib:${LD_LIBRARY_PATH:-}"
export PATH="/shared/artifacts/protobuf/v4.25.3/bin:${PATH}"
export PROTOC="/shared/artifacts/protobuf/v4.25.3/bin/protoc"
```

### manifest.json

Metadata for reproducibility and license compliance:

```json
{
  "name": "protobuf",
  "version": "v4.25.3",
  "git_sha": "abc123def456...",
  "git_url": "https://github.com/protocolbuffers/protobuf",
  "build_date": "2026-02-18T14:30:00Z",
  "arch": "ppc64le",
  "license_spdx": "BSD-3-Clause",
  "license_files": ["LICENSE"],
  "depends_on": ["abseil-cpp:20240116.2"],
  "provides": ["protoc", "libprotobuf.so.25"]
}
```

---

## License Compliance

### Why This Matters

Python wheels must include license information for bundled dependencies per:
- PyPA (Python Packaging Authority) standards
- `auditwheel repair` validation
- Legal/compliance requirements

### License Collection

Each artifact's `manifest.json` tracks license info. During wheel build:

```bash
post_build() {
    collect_dependency_licenses "$(pwd)/licenses"
}
```

This produces:
```
my_package-1.0.0.dist-info/
└── licenses/
    ├── THIRD_PARTY_LICENSES.txt   # Summary
    ├── protobuf-BSD-3-Clause.txt
    ├── abseil-Apache-2.0.txt
    └── ...
```

---

## Version Naming (Local Versions)

### PyPA Local Version Identifiers

Per PEP 440, packages can include local version segments:

```
1.0.0                    # Base version
1.0.0+ppc64le            # Architecture-specific
1.0.0+ppc64le.20260218   # With build date
```

### When to Use

| Scenario | Local Version |
|----------|---------------|
| Standard rebuild | None |
| Architecture-optimized (POWER9) | `+ppc64le` |
| Different dependency versions | `+ppc64le.proto25` |

The build system (not templates) controls `LOCAL_VERSION_TAG`.

---

## Example: vllm Dependency Chain

vllm requires ~50 packages built from source. With this system:

### Before: 1626-line monolithic script

### After: ~20 focused scripts with build_info.json declarations

```
# Tier 0 (no deps) - provides_artifact only, no build_deps
o/openblas/build_info.json      → "provides_artifact": "openblas"
a/abseil-cpp/build_info.json    → "provides_artifact": "abseil-cpp"
l/libvpx/build_info.json        → "provides_artifact": "libvpx"
l/lame/build_info.json          → "provides_artifact": "lame"
o/opus/build_info.json          → "provides_artifact": "opus"
...

# Tier 1 - provides artifact, depends on Tier 0
p/protobuf/build_info.json      → "provides_artifact": "protobuf"
                                  "build_deps": ["abseil-cpp:20240116.2"]

f/ffmpeg/build_info.json        → "provides_artifact": "ffmpeg"
                                  "build_deps": ["libvpx:v1.13.1", "lame:3.100", "opus:v1.3.1"]

l/llvm/build_info.json          → "provides_artifact": "llvm"

# Tier 2 - depends on Tier 1
p/pytorch/build_info.json       → "provides_artifact": "pytorch"
                                  "build_deps": ["openblas:v0.3.29", "protobuf:v4.25.3"]

l/llvmlite/build_info.json      → "provides_artifact": "llvmlite"
                                  "build_deps": ["llvm:15.0.7"]

# Tier 3 - consumer only (no provides_artifact)
n/numba/build_info.json         → "build_deps": ["llvmlite:v0.44.0"]
t/torchvision/build_info.json   → "build_deps": ["pytorch:v2.6.0"]
p/pyarrow/build_info.json       → "build_deps": ["arrow:latest"]

# Tier 4 - final consumer
v/vllm/build_info.json          → "build_deps": ["pytorch:v2.6.0", "torchvision:v0.21.0",
                                                 "pyarrow:latest", "numba:0.62.0"]
```

Build order determined automatically by tsort on the preprocessor-parsed JSON.

---

## Quick Reference

### build_info.json Fields (preprocessor)

| Field | Purpose | Example |
|-------|---------|---------|
| `provides_artifact` | What this script builds (optional) | `"protobuf"` |
| `build_deps` | Array of dependencies (optional) | `["abseil-cpp:20240116.2"]` |

### Shell Variables (runtime)

| Variable | Purpose | Example |
|----------|---------|---------|
| `PROVIDES_ARTIFACT` | What this script builds | `"protobuf"` |
| `BUILD_DEPS` | Space-separated dependencies | `"abseil-cpp:20240116.2"` |

### Environment Variables (set by execution engine)

| Variable | Purpose | Default |
|----------|---------|---------|
| `ARTIFACT_WORKSPACE` | Shared artifact storage across builds | `${OUTPUT_DIR}/artifacts` |

### Helper Functions

| Function | Purpose |
|----------|---------|
| `artifact_dir <name> [version]` | Get artifact directory path |
| `source_artifact <name> [version]` | Source artifact's env.sh |
| `generate_artifact_manifest` | Create manifest.json |
| `collect_dependency_licenses` | Gather licenses for wheel |

### Files

| File | Purpose |
|------|---------|
| `{pkg}/build_info.json` | Declares `provides_artifact` and `build_deps` |
| `templates/python.sh` | Main template, auto-sources artifacts.sh if `build_deps` present |
| `templates/lib/artifacts.sh` | Artifact helper functions (`artifact_dir`, `source_artifact`, etc.) |
| `templates/lib/common.sh` | Core functions (logging, clone, etc.) |
| `templates/template-tools/script/ci/parse_build_info.py` | Parses build_info.json, performs tsort |

---

## Gotchas and Best Practices

### GitHub Tag Format Variations

**Critical**: GitHub tag formats vary significantly by project. Always verify the exact tag format before writing scripts.

| Project | Tag Format | Example |
|---------|------------|---------|
| Most projects | `vX.Y.Z` | `v1.2.3` |
| Boost | `boost-X.Y.Z` | `boost-1.86.0` |
| LLVM | `llvmorg-X.Y.Z` | `llvmorg-18.1.8` |
| HDF5 | `hdf5-X_Y_Z` (underscores) | `hdf5-1_14_3` |
| hwloc | `hwloc-X.Y.Z` | `hwloc-2.9.3` |
| Abseil | `YYYYMMDD.N` (no prefix) | `20240116.2` |
| Snappy | `X.Y.Z` (no prefix) | `1.2.1` |
| FFmpeg | `nX.Y` | `n7.0` |
| Lame | `RELEASE__X_Y` | `RELEASE__3_100` |

**How to verify**:
```bash
git ls-remote --tags https://github.com/org/repo | grep -E 'refs/tags/' | tail -20
```

**Common failures**:
```
error: pathspec 'v2.11.2' did not match any file(s) known to git
```
This means the tag format is wrong. Check the actual tags in the repo.

### Artifact Cleanup

Use `cleanup_artifact_dir` to remove unnecessary files (man pages, docs) after installation:

```bash
custom_install() {
    # ... build and install ...

    make install PREFIX="${ARTIFACT_DIR}"

    # Remove unnecessary files (man pages, docs)
    cleanup_artifact_dir "${ARTIFACT_DIR}" share

    # Copy license
    cp LICENSE "${ARTIFACT_DIR}/"

    # ... generate env.sh ...
}
```

**Function signature**:
```bash
cleanup_artifact_dir <artifact_dir> [targets...]
```

- Default target is `share` (contains man pages, docs, etc.)
- Multiple targets: `cleanup_artifact_dir "${ARTIFACT_DIR}" share bin`
- Called after `make install` but before copying license and generating env.sh

**What typically ends up in `share/`**:
- `share/man/` - man pages
- `share/doc/` - documentation
- `share/aclocal/` - autoconf macros
- `share/cmake/` - CMake modules (sometimes redundant)

### Artifact Provider Script Pattern

Standard pattern for Tier 0/1 artifact providers:

```bash
#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : mylib
# Version       : vX.Y.Z
# Source repo   : https://github.com/org/mylib
# Tested on     : UBI:9.3
# Language      : C/C++
# Script License: Apache License, Version 2 or later
# Maintainer    : IBM
#
# Notes:
#   - Tier N artifact provider (depends on: dep1, dep2)
#   - Brief description of what this provides
#   - Required by: consumer1, consumer2
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="mylib"
PACKAGE_VERSION="${1:-vX.Y.Z}"  # Use EXACT GitHub tag format!
PACKAGE_URL="https://github.com/org/mylib"

# =============================================================================
# Artifact Declaration
# =============================================================================
PROVIDES_ARTIFACT="mylib"
BUILD_DEPS="dep1 dep2"  # Space-separated, omit for Tier 0

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ cmake make"
DEB_DEP_PKGS="git gcc g++ cmake make"
SLES_DEP_PKGS="git gcc gcc-c++ cmake make"

# =============================================================================
# CALLBACK: custom_install
# =============================================================================
custom_install() {
    local ARTIFACT_DIR
    ARTIFACT_DIR="$(artifact_dir mylib "${PACKAGE_VERSION}")"

    # Check if already built (idempotency)
    if [[ -f "${ARTIFACT_DIR}/env.sh" ]]; then
        log_info "mylib artifact already exists at ${ARTIFACT_DIR}"
        return 0
    fi

    # Source dependencies (Tier 1+ only)
    if ! source_artifact dep1; then
        log_error "dep1 artifact not found!"
        log_error "Build dep1 first: d/dep1/dep1.sh"
        return 1
    fi

    log_info "Building mylib ${PACKAGE_VERSION} to ${ARTIFACT_DIR}"
    mkdir -p "${ARTIFACT_DIR}"

    # Build (cmake example)
    mkdir -p build && cd build
    cmake \
        -DCMAKE_INSTALL_PREFIX="${ARTIFACT_DIR}" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_LIBDIR=lib \
        -DBUILD_SHARED_LIBS=ON \
        -DBUILD_TESTING=OFF \
        .. || { log_error "CMake configuration failed"; return 1; }

    make -j"$(nproc)" || { log_error "Build failed"; return 1; }
    make install || { log_error "Install failed"; return 1; }
    cd ..

    # Remove unnecessary files (man pages, docs)
    cleanup_artifact_dir "${ARTIFACT_DIR}" share

    # Copy license
    cp LICENSE "${ARTIFACT_DIR}/"

    # Generate env.sh
    cat > "${ARTIFACT_DIR}/env.sh" << EOF
# mylib ${PACKAGE_VERSION} environment
export MYLIB_PREFIX="${ARTIFACT_DIR}"
export LD_LIBRARY_PATH="${ARTIFACT_DIR}/lib:\${LD_LIBRARY_PATH:-}"
export LIBRARY_PATH="${ARTIFACT_DIR}/lib:\${LIBRARY_PATH:-}"
export CPATH="${ARTIFACT_DIR}/include:\${CPATH:-}"
export PKG_CONFIG_PATH="${ARTIFACT_DIR}/lib/pkgconfig:\${PKG_CONFIG_PATH:-}"
export CMAKE_PREFIX_PATH="${ARTIFACT_DIR}:\${CMAKE_PREFIX_PATH:-}"
EOF

    # Generate manifest
    generate_artifact_manifest "${ARTIFACT_DIR}" \
        "mylib" "${PACKAGE_VERSION}" \
        "${PACKAGE_URL}" "LICENSE-SPDX" \
        "dep1 dep2"  # List dependencies

    log_info "mylib installed to ${ARTIFACT_DIR}"
}

# =============================================================================
# Skip tests for native library build
# =============================================================================
SKIP_TESTS=true

# =============================================================================
# Execute the build
# =============================================================================
source "${SCRIPT_DIR}/../../templates/python.sh"
```

### Common env.sh Exports

| Export | Purpose |
|--------|---------|
| `*_PREFIX` | Base directory for the artifact |
| `LD_LIBRARY_PATH` | Runtime library search path |
| `LIBRARY_PATH` | Compile-time library search path |
| `CPATH` | Header include path |
| `PATH` | For binaries (protoc, thrift, ffmpeg, etc.) |
| `PKG_CONFIG_PATH` | For pkg-config discovery |
| `CMAKE_PREFIX_PATH` | For CMake find_package() |

### Error Handling Pattern

Always use the error handling pattern for critical operations:

```bash
./configure ... || { log_error "Configure failed"; return 1; }
make -j"$(nproc)" || { log_error "Build failed"; return 1; }
make install || { log_error "Install failed"; return 1; }
```

### Header-Only Libraries

For header-only libraries (rapidjson, xsimd), the install is simpler:

```bash
custom_install() {
    # ... cmake install just copies headers ...

    # env.sh only needs include path
    cat > "${ARTIFACT_DIR}/env.sh" << EOF
# xsimd ${PACKAGE_VERSION} environment
export XSIMD_PREFIX="${ARTIFACT_DIR}"
export CPATH="${ARTIFACT_DIR}/include:\${CPATH:-}"
export CMAKE_PREFIX_PATH="${ARTIFACT_DIR}:\${CMAKE_PREFIX_PATH:-}"
EOF
}
```

### Python Package with Native Artifact

For packages like pytorch that provide both a Python package and native artifacts:

```bash
PROVIDES_ARTIFACT="pytorch"  # Provides native libs for torchvision, etc.
BUILD_DEPS="openblas protobuf"

custom_install() {
    # Build pytorch
    # Install to both site-packages AND artifact dir
    # Generate env.sh that sets PYTHONPATH and library paths
}
```

---

## Tracking Progress

The file `templates/docs/vllm_dependency_tiers.csv` tracks the status of all vllm dependencies:

```csv
package_name,package_version,language,language_version,github_repo,status,build_deps
openblas,v0.3.29,c,N/A,https://github.com/OpenMathLib/OpenBLAS,script_ready,
protobuf,v25.3,c++,N/A,https://github.com/protocolbuffers/protobuf,script_ready,abseil-cpp
```

**Status values**:
- `script_ready` - Script exists with correct `provides_artifact`
- `script_missing` - No script exists yet
- `needs_review` - Script exists but may need updates
