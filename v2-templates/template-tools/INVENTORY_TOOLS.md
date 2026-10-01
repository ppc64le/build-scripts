# Package Inventory Tools

Tools for generating and working with package inventories from the build-scripts repository.

## Overview

| Tool | Purpose |
|------|---------|
| `generate_package_inventory.py` | Scan build-scripts tree and generate CSV inventory of all packages |
| `mkbuild-list` | Generate build list for packages with all transitive dependencies |

---

## generate_package_inventory.py

Scans a build-scripts directory tree for `build_info.json` files and generates a comprehensive CSV inventory of all packages.

### Usage

```bash
# Scan current directory, output to stdout
./generate_package_inventory.py

# Scan current directory, save to file
./generate_package_inventory.py -o inventory.csv

# Scan specific directory
./generate_package_inventory.py /path/to/build-scripts

# Scan subdirectory (e.g., just python packages)
./generate_package_inventory.py ./p

# Quiet mode (no progress messages)
./generate_package_inventory.py -q -o inventory.csv
```

### Options

| Option | Description |
|--------|-------------|
| `DIRECTORY` | Directory to scan (default: current directory) |
| `-o, --output FILE` | Output CSV file (default: stdout) |
| `-q, --quiet` | Suppress progress messages |
| `-h, --help` | Show help |

### Output Columns

| Column | Description |
|--------|-------------|
| Package Name | Package name from build_info.json |
| Package Version | Default version from build_info.json |
| Language | Detected language (python, c++, node, go, etc.) |
| Language Version | Language version if specified (often empty) |
| GitHub URL | Repository URL |
| Build Deps | Comma-separated list of build dependencies |
| Provides Artifact | Artifact name if this package is an artifact provider |

### Language Detection

The tool detects language by examining which template the build script sources:

| Template | Detected Language |
|----------|-------------------|
| `python.sh` | python |
| `node.sh` | node |
| `go.sh` | go |
| `java.sh` | java |
| `ruby.sh` | ruby |
| `base.sh` | Falls back to `language` field in build_info.json (c++, c, fortran, rust) |

### Examples

```bash
# Generate full inventory
./generate_package_inventory.py . -o full_inventory.csv

# Count packages by language
./generate_package_inventory.py -q | cut -d',' -f3 | sort | uniq -c | sort -rn

# List all artifact providers
./generate_package_inventory.py -q | awk -F',' '$7 != ""' | cut -d',' -f1,7

# Find packages with no GitHub URL
./generate_package_inventory.py -q | awk -F',' '$5 == ""'
```

---

## mkbuild-list

Generates a build list for one or more packages including all transitive dependencies, ordered so dependencies are built first (topological sort).

### Usage

```bash
# Build list for single package
./mkbuild-list vllm

# Build list for multiple packages
./mkbuild-list pytorch torchvision torchaudio

# Output to file
./mkbuild-list vllm -o vllm-build.csv

# Use existing inventory (faster for repeated queries)
./mkbuild-list -i inventory.csv vllm

# Scan specific directory
./mkbuild-list -d /path/to/build-scripts arrow

# Quiet mode
./mkbuild-list -q vllm > build.csv
```

### Options

| Option | Description |
|--------|-------------|
| `PACKAGE` | One or more package names (required) |
| `-i, --inventory FILE` | Use existing inventory CSV instead of scanning |
| `-d, --dir DIR` | Directory to scan for build_info.json (default: cwd) |
| `-o, --output FILE` | Output CSV file (default: stdout) |
| `-q, --quiet` | Suppress progress messages |
| `-h, --help` | Show help |

### Output

The output CSV has the same columns as `generate_package_inventory.py`, but contains only:
- The requested package(s)
- All transitive build dependencies

Packages are ordered topologically (dependencies first), so you can build them in order from top to bottom.

### Examples

```bash
# See what's needed to build vllm
./mkbuild-list vllm
# Output: 21 packages including pytorch, arrow, grpc, protobuf, etc.

# See what's needed for pytorch
./mkbuild-list pytorch
# Output: 4 packages: abseil-cpp, openblas, protobuf, pytorch

# Generate build list and count by language
./mkbuild-list vllm -q | cut -d',' -f3 | sort | uniq -c

# Create focused build manifest
./mkbuild-list arrow -o arrow-build.csv
```

### Dependency Resolution

The tool resolves dependencies by:

1. Reading `Build Deps` column from inventory
2. Recursively finding all transitive dependencies
3. Topologically sorting so leaf dependencies come first

**Example: vllm dependency chain**

```
Tier 0 (no deps):     abseil-cpp, boost, c-ares, gflags, openblas,
                      rapidjson, snappy, utf8proc, xsimd, zstd

Tier 1 (Tier 0 deps): protobuf, re2, thrift

Tier 2 (Tier 1 deps): grpc_cpp, orc

Tier 3 (Tier 2 deps): arrow, pytorch

Tier 4 (Tier 3 deps): pyarrow, torchaudio, torchvision

Target:               vllm
```

### Handling Missing Packages

If a dependency is referenced but not found in the inventory, `mkbuild-list` will:
- Print a warning (unless `-q` is used)
- Continue processing other dependencies
- Not include the missing package in output

This can happen when:
- A dependency hasn't been added to build-scripts yet
- There's a typo in the `build_deps` field
- You're scanning a subset of the repository

---

## Workflow Example

```bash
# 1. Generate full inventory once
./generate_package_inventory.py . -o inventory.csv

# 2. Create build lists for different targets
./mkbuild-list -i inventory.csv vllm -o builds/vllm.csv
./mkbuild-list -i inventory.csv pytorch -o builds/pytorch.csv
./mkbuild-list -i inventory.csv arrow -o builds/arrow.csv

# 3. Compare build requirements
wc -l builds/*.csv
#   5 builds/pytorch.csv   (4 packages + header)
#  18 builds/arrow.csv     (17 packages + header)
#  22 builds/vllm.csv      (21 packages + header)

# 4. Find common dependencies
comm -12 <(cut -d',' -f1 builds/pytorch.csv | sort) \
         <(cut -d',' -f1 builds/arrow.csv | sort)
```

---

## Integration with CI/CD

These tools can be used to:

1. **Generate build manifests** for CI pipelines
2. **Validate dependency chains** before submitting builds
3. **Identify missing artifacts** that need to be built first
4. **Create subset builds** for testing specific packages

Example CI usage:

```bash
# Generate build order for PR that modifies pytorch
./mkbuild-list pytorch torchvision torchaudio vllm -q > build-order.csv

# Submit builds in order
while IFS=, read -r name version lang langver url deps artifact; do
    [ "$name" = "Package Name" ] && continue  # Skip header
    echo "Building: $name $version"
    # trigger_build "$name" "$version"
done < build-order.csv
```
