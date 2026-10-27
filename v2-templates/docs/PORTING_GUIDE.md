# Build Script Porting Guide

This guide covers converting legacy build scripts to the new invocable template format. It's designed for both human porters and LLM assistants performing conversions.

## Table of Contents

1. [Overview](#overview)
2. [Quick Start: Simple Packages](#quick-start-simple-packages)
3. [Environment Assumptions](#environment-assumptions)
4. [Conversion Process](#conversion-process)
5. [Callback Reference](#callback-reference)
6. [Common Patterns](#common-patterns)
7. [Gotchas and Pitfalls](#gotchas-and-pitfalls)
8. [Complexity Levels](#complexity-levels)
9. [Testing Considerations](#testing-considerations)
10. [Checklist](#checklist)

---

## Overview

### Old Format (Legacy)
```bash
#!/bin/bash -e
PACKAGE_NAME=foo
PACKAGE_VERSION=${1:-v1.0.0}
PACKAGE_URL=https://github.com/org/foo.git

yum install -y git python3 python3-devel ...
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

pip3 install .

if ! pytest; then
    echo "...test fail..."
    exit 2
fi
exit 0
```

### New Format (Invocable Template)
```bash
#!/bin/bash -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PACKAGE_NAME="foo"
PACKAGE_VERSION="${1:-v1.0.0}"
PACKAGE_URL="https://github.com/org/foo"

RH_DEP_PKGS="git python3 python3-devel python3-pip"
DEB_DEP_PKGS="git python3 python3-dev python3-pip python3-venv"
SLES_DEP_PKGS="git python3 python3-devel python3-pip"

source "${SCRIPT_DIR}/../../templates/python.sh"
```

### Key Differences

| Aspect | Legacy | New Template |
|--------|--------|--------------|
| Package manager | Hardcoded (yum/apt) | Multi-distro via variables |
| Clone/checkout | Manual | Handled by template |
| Virtual envs | None (system pip) | Isolated .venv-build/.venv-test |
| Build method | pip install / setup.py | python -m build (PEP 517) |
| Exit codes | Manual echo/exit | Template report_* functions |
| Customization | Inline code | Callback functions |

---

## Quick Start: Simple Packages

For packages with no special build requirements:

```bash
#!/bin/bash -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PACKAGE_NAME="requests"
PACKAGE_VERSION="${1:-v2.31.0}"
PACKAGE_URL="https://github.com/psf/requests"

RH_DEP_PKGS="git python3 python3-devel python3-pip gcc"
DEB_DEP_PKGS="git python3 python3-dev python3-pip python3-venv gcc"

source "${SCRIPT_DIR}/../../templates/python.sh"
```

That's it. The template handles everything else.

---

## Environment Assumptions

The container environment provides these tools pre-installed:

| Tool | Notes |
|------|-------|
| **Python** | Multiple versions available, selected via PYTHON_VERSION |
| **Rust/Cargo** | For packages with Rust extensions |
| **Node/npm** | For packages requiring JS tooling |
| **gcc/g++** | C/C++ compilation |
| **git** | Always available |
| **make/cmake** | Build tools |

**Important**: The repository is pre-cloned with full history before the script runs. The template's `clone_repository()` function detects existing clones and uses them.

---

## Conversion Process

### Step 1: Analyze the Legacy Script

Identify these elements:

1. **Package metadata** (name, version, URL)
2. **System dependencies** (yum/apt packages)
3. **Build steps** (what happens between clone and install)
4. **Test command** (pytest invocation, deselects, etc.)
5. **Special requirements** (submodules, code generation, patches)

### Step 2: Map to Template Structure

```bash
#!/bin/bash -e
# [Keep the header comments from original]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# REQUIRED: Package metadata
PACKAGE_NAME="..."
PACKAGE_VERSION="${1:-v1.0.0}"
PACKAGE_URL="..."

# REQUIRED: Dependencies (convert from yum/apt)
RH_DEP_PKGS="..."
DEB_DEP_PKGS="..."
SLES_DEP_PKGS="..."  # optional but recommended

# CALLBACKS: Define any needed hooks here (before source line)

# Execute template
source "${SCRIPT_DIR}/../../templates/python.sh"
```

### Step 3: Convert Dependencies

**From:**
```bash
yum install -y git gcc gcc-c++ make openssl-devel python3-devel python3-pip
```

**To:**
```bash
RH_DEP_PKGS="git gcc gcc-c++ make openssl-devel python3-devel python3-pip"
DEB_DEP_PKGS="git gcc g++ make libssl-dev python3-dev python3-pip python3-venv"
SLES_DEP_PKGS="git gcc gcc-c++ make libopenssl-devel python3-devel python3-pip"
```

**Common Package Mappings:**

| Purpose | Red Hat | Debian | SUSE |
|---------|---------|--------|------|
| OpenSSL dev | openssl-devel | libssl-dev | libopenssl-devel |
| Python dev | python3-devel | python3-dev | python3-devel |
| Python venv | (included) | python3-venv | (included) |
| libffi | libffi-devel | libffi-dev | libffi-devel |
| zlib | zlib-devel | zlib1g-dev | zlib-devel |
| jpeg | libjpeg-devel | libjpeg-dev | libjpeg-devel |
| bzip2 | bzip2-devel | libbz2-dev | libbz2-devel |

### Step 4: Identify Needed Callbacks

| If the legacy script... | Use callback... |
|-------------------------|-----------------|
| Runs commands before clone | `pre_clone()` |
| Has git submodules | `post_clone()` (if extra steps needed beyond init) |
| Applies patches | `post_clone()` |
| Generates code (cython, llhttp, etc.) | `post_clone()` or `pre_build()` |
| Installs extra pip packages for build | `pre_build()` |
| Runs make or custom build | `custom_install()` |
| Has custom test invocation | `custom_test_command()` |
| Deselects specific tests | `custom_test_command()` |

---

## Callback Reference

Define these functions **before** the `source` line.

### pre_clone()
**When**: Before git clone  
**Use for**: Extra system setup, environment variables

```bash
pre_clone() {
    export CFLAGS="-O2 -fPIC"
    export LDFLAGS="-L/usr/local/lib"
}
```

### post_clone()
**When**: After checkout, inside repo directory  
**Use for**: Submodule setup, patches, code generation

```bash
post_clone() {
    # Extra submodule handling
    git submodule update --init --recursive
    
    # Apply patches
    git apply "${SCRIPT_DIR}/patches/fix.patch"
    
    # Code generation (e.g., llhttp for aiohttp)
    if [[ -d "vendor/llhttp" ]]; then
        (cd vendor/llhttp && npm install && npm run build)
    fi
}
```

### pre_build()
**When**: After post_clone, before python -m build  
**Context**: Inside .venv-build virtual environment  
**Use for**: Installing build dependencies, generating code

```bash
pre_build() {
    pip install cython numpy
    
    # Generate C files from Cython (IMPORTANT - see Gotchas)
    cython -3 src/*.pyx
}
```

### post_build()
**When**: After successful install  
**Use for**: Verification, sanity checks

```bash
post_build() {
    python -c "import mypackage; print(mypackage.__version__)"
}
```

### custom_install()
**When**: Replaces entire build phase  
**Use for**: Packages that can't use python -m build

```bash
custom_install() {
    ${PYTHON_VERSION} -m venv .venv-build
    source .venv-build/bin/activate
    
    pip install --upgrade pip setuptools wheel
    
    # Custom build logic
    make
    pip install .
    
    deactivate
    return 0  # or return 1 on failure
}
```

### custom_test_command()
**When**: Replaces default test discovery
**Context**: Inside .venv-test virtual environment
**Use for**: Custom pytest args, test deselects, specific test files

```bash
custom_test_command() {
    # Install test deps
    pip install -r requirements-test.txt || true
    pip install --upgrade "pytest>=7.0" || true

    # Remove plugins that crash during entrypoint loading
    pip uninstall -y pytest-cov pytest-xdist pytest-codspeed 2>/dev/null || true

    # Clear addopts and run with deselects
    pytest \
        -o "addopts=" \
        --deselect tests/test_slow.py \
        -k "not integration" \
        --disable-warnings
}
```

**Note**: The template's default pytest already handles plugin issues. `custom_test_command()` must handle them explicitly.

### post_test()
**When**: After tests pass  
**Use for**: Cleanup, artifact collection

```bash
post_test() {
    cp .coverage "${SCRIPT_DIR}/artifacts/"
}
```

---

## Common Patterns

### Pattern: Cython Extensions

**Problem**: `python -m build` uses isolation, cython not available.

```bash
pre_build() {
    pip install cython
    # Run from package dir so .pxi includes resolve correctly
    (cd src && cython -3 *.pyx)
}
```

### Pattern: npm-based Code Generation

```bash
post_clone() {
    if [[ -d "vendor/llhttp" ]]; then
        (cd vendor/llhttp && npm install && npm run build)
    fi
}
```

### Pattern: Test Deselects (Platform-Specific Failures)

```bash
custom_test_command() {
    pip install -r requirements/test.txt || true
    pip install --upgrade "pytest>=7.0" || true

    # Remove plugins that crash during entrypoint loading
    pip uninstall -y pytest-cov pytest-xdist pytest-codspeed 2>/dev/null || true

    # Clear addopts from setup.cfg (may include --cov flags)
    pytest \
        -o "addopts=" \
        --deselect tests/test_imports.py \
        -k "not test_flaky and not test_timing" \
        --disable-warnings
}
```

**Note**: The plugin uninstall and `-o "addopts="` pattern is often necessary. See [Gotcha #9](#9-pytest-plugin-crashes-during-entrypoint-loading) for details.

### Pattern: Requirements File with Bad Pins

**Problem**: requirements.txt pins old versions causing conflicts.

```bash
pre_build() {
    # Install what we need directly, skip requirements file
    pip install cython numpy
    # NOT: pip install -r requirements/build.txt
}
```

### Pattern: Make-based Build

```bash
custom_install() {
    ${PYTHON_VERSION} -m venv .venv-build
    source .venv-build/bin/activate
    
    pip install --upgrade pip wheel
    make
    pip install .
    
    deactivate
    return 0
}
```

### Pattern: Patches

```bash
post_clone() {
    # Inline sed fix
    sed -i 's/old_api/new_api/g' src/module.py
    
    # Or apply patch file
    git apply "${SCRIPT_DIR}/patches/compatibility.patch"
}
```

### Pattern: Environment Variables

```bash
pre_clone() {
    export CFLAGS="-O2"
    export PACKAGE_SPECIFIC_VAR="value"
}
```

---

## Gotchas and Pitfalls

### 1. Cython Extensions

**Context**: The template now uses `python -m build --no-isolation` and runs `pre_build()` inside `.venv-build`, so cython is available during the build.

**Pattern**: Install cython and generate .c files in `pre_build()`:
```bash
pre_build() {
    pip install cython  # Installs into .venv-build
    # Run from the directory containing .pyx files so .pxi includes are found
    (cd src && cython -3 *.pyx)
}
```

**Why this works**: `pre_build()` runs inside the venv, so `pip install cython` works. The `--no-isolation` flag ensures the build uses the venv's cython.

### 1b. Cython Include Files (.pxi) Not Found

**Problem**: Cython `.pyx` files include `.pxi` files with relative paths.

**Symptom**:
```
Error compiling Cython file:
include "_headers.pxi"
        ^
'_headers.pxi' not found
```

**Solution 1**: Run cython from within the package directory:
```bash
# WRONG - includes won't resolve:
cython -3 aiohttp/*.pyx

# CORRECT - run from package dir:
(cd aiohttp && cython -3 *.pyx)
```

**Solution 2**: The `.pxi` file might be **generated**, not checked in.
Check for generator scripts (often `tools/gen.py` or similar):
```bash
pre_build() {
    pip install cython
    # Generate .pxi files first
    python tools/gen.py
    # Then run cython
    (cd aiohttp && cython -3 *.pyx)
}
```

**How to detect**: Look in the Makefile for targets that generate `.pxi` or `.c` files before the cythonize step.

**Watch out**: Generator scripts may import runtime dependencies:
```bash
pre_build() {
    # gen.py imports multidict - must install first
    pip install cython multidict
    if ! python tools/gen.py; then
        log_error "Failed to generate headers"
        return 1
    fi
    if ! (cd aiohttp && cython -3 *.pyx); then
        log_error "Failed to run cython"
        return 1
    fi
}
```

### 2. Requirements Files with Version Pins

**Problem**: Old requirements files pin versions that conflict with current Python.

**Symptom**:
```
ERROR: pip's dependency resolver does not currently take into account...
typing-extensions 4.1.1 which is incompatible
```

**Solution**: Install only what you need directly:
```bash
pre_build() {
    pip install cython  # Not: pip install -r requirements/cython.txt
}
```

### 3. Submodules Not Initialized

**Problem**: Template initializes submodules, but some repos need extra steps.

**Symptom**: Missing vendor directories, build failures.

**Solution**: Add explicit init in post_clone:
```bash
post_clone() {
    git submodule update --init --recursive
}
```

### 4. Tests Require Package to be Installed

**Problem**: Some test suites import the installed package, not source.

**Note**: The template handles this - it installs the package in .venv-test before running tests.

### 5. System Python Conflicts

**Problem**: Legacy scripts modified system python packages.

**Example from legacy**: `yum remove -y python3-requests`

**Solution**: Not needed with venv isolation. Remove these lines.

### 6. Hardcoded Python Version

**Problem**: Legacy scripts use `python3` or `pip3` directly.

**Solution**: Template uses `${PYTHON_VERSION}` variable. In callbacks, use:
- `python` (inside activated venv)
- `pip` (inside activated venv)  
- `${PYTHON_VERSION}` (outside venv)

### 7. Rust Installation

**Problem**: Legacy scripts install rust.

**Solution**: Container provides rust. Remove rustup installation code.

### 8. Directory Navigation

**Problem**: Legacy scripts `cd` around.

**Note**: After `post_clone()`, you're in the repository directory. The template handles this.

### 9. Pytest Plugin Crashes During Entrypoint Loading

**Problem**: Pytest plugins like `pytest-cov`, `pytest-xdist` crash during import before `-p no:` flags are processed.

**Symptom**:
```
File "/...site-packages/pytest_cov/plugin.py", line 150, in pytest_load_initial_conftests
    early_config.pluginmanager.register(plugin, '_cov')
...
pytest.PytestDeprecationWarning: The hookimpl CovPlugin.pytest_configure_node uses old-style configuration options
```

**Why `-p no:cov` doesn't work**: Plugins are loaded via setuptools entrypoints during pytest initialization, BEFORE command line arguments are processed. If a plugin crashes during entrypoint registration, pytest never gets to the `-p no:` flag.

**Solution**: Uninstall the problematic plugins AND clear default pytest options:
```bash
custom_test_command() {
    pip install -r requirements/test.txt || true
    pip install --upgrade "pytest>=7.0" || true

    # Remove plugins that crash during entrypoint loading
    pip uninstall -y pytest-cov pytest-xdist pytest-codspeed 2>/dev/null || true

    # Clear addopts from setup.cfg/pyproject.toml (may include --cov flags)
    pytest -o "addopts=" tests/
}
```

**Why `-o "addopts="`**: Projects often have `--cov=package` in their `setup.cfg` or `pyproject.toml`. After uninstalling pytest-cov, pytest doesn't recognize `--cov` and fails with "unrecognized arguments". Clearing `addopts` removes these default flags.

**Common offenders**:
- `pytest-cov` - hook compatibility issues across pytest versions
- `pytest-xdist` - version requirements conflict with pinned pytest
- `pytest-codspeed` - optional performance plugin

**Note**: The template's default pytest path already handles this, but `custom_test_command()` needs to do it explicitly.

### 10. Setuptools Version Compatibility

**Problem**: The template pins `setuptools<70` by default to protect legacy packages that rely on `pkg_resources` or older APIs. However, modern packages may need newer setuptools for features like `license_files` (PEP 639), dynamic metadata, etc.

**Symptom** (needs older setuptools):
```
AttributeError: module 'pkg_resources' has no attribute ...
```

**Symptom** (needs newer setuptools):
```
error: Unknown metadata field: license_files
```

**Solution**: Override `SETUPTOOLS_VERSION` before sourcing the template:

```bash
# Default behavior (most packages) - no change needed
# Gets setuptools<70

# Modern package needing PEP 639 license_files, dynamic metadata, etc.
SETUPTOOLS_VERSION=">=70,<82"
source "${SCRIPT_DIR}/../../templates/python.sh"

# Bleeding edge (package has no pkg_resources dependency at all)
SETUPTOOLS_VERSION=""  # Empty = let pip resolve latest
source "${SCRIPT_DIR}/../../templates/python.sh"

# Specific version pin if needed
SETUPTOOLS_VERSION="==69.5.1"
source "${SCRIPT_DIR}/../../templates/python.sh"
```

**How to detect which you need**:
- `setuptools<70` (default): Package uses `pkg_resources`, has `setup.py` only, or is a legacy package
- `setuptools>=70`: Package uses `license_files` in metadata, `dynamic` fields in pyproject.toml, or other modern features
- `setuptools>=82`: Only if package explicitly requires it and does NOT use `pkg_resources` at all

**Note**: As of early 2026, `setuptools>=82` removed `pkg_resources` entirely. Most packages should stay with `<70` or `>=70,<82` unless you've verified no `pkg_resources` usage.

---

## Complexity Levels

### Level 1: Simple (No Callbacks)
- Pure Python packages
- No C extensions
- Standard test suite

**Example**: requests, click, attrs

```bash
PACKAGE_NAME="requests"
PACKAGE_VERSION="${1:-v2.31.0}"
PACKAGE_URL="https://github.com/psf/requests"
RH_DEP_PKGS="git python3 python3-devel python3-pip"
DEB_DEP_PKGS="git python3 python3-dev python3-pip python3-venv"
source "${SCRIPT_DIR}/../../templates/python.sh"
```

### Level 2: Moderate (1-2 Callbacks)
- Has C extensions (needs gcc in deps)
- Custom test command (deselects)
- Simple patches

**Example**: pyyaml, msgpack

```bash
# ... metadata and deps ...

custom_test_command() {
    pytest -k "not test_slow"
}

source "${SCRIPT_DIR}/../../templates/python.sh"
```

### Level 3: Complex (Multiple Callbacks)
- Cython extensions
- Code generation (npm, make, etc.)
- Multiple test deselects
- Special build requirements

**Example**: aiohttp, numpy, pandas

```bash
# ... metadata and deps ...

post_clone() {
    # Generate code
    (cd vendor/parser && npm install && npm run build)
}

pre_build() {
    pip install cython
    cython -3 src/*.pyx
}

custom_test_command() {
    pip install -r requirements/test.txt
    pytest --deselect tests/slow/ -k "not flaky"
}

source "${SCRIPT_DIR}/../../templates/python.sh"
```

### Level 4: Custom Build (custom_install)
- Can't use python -m build
- Requires make or custom tooling
- Complex build orchestration

**Example**: Some scientific packages, packages with vendored C libraries

---

## Testing Considerations

### Multi-Version Testing

Scripts are tested with:
- Multiple Python versions (3.9, 3.10, 3.11, 3.12, 3.13, 3.14)
- Multiple package versions (specified via $1 argument)

**Ensure**:
- No hardcoded Python version
- Version-specific test deselects are documented
- Default version in script is known-good

### Platform Testing

Scripts run on multiple architectures (x86_64, ppc64le, s390x).

**Document**: Platform-specific test failures and deselects.

### Exit Codes

The template uses:
- `0` - Success
- `1` - Clone or install failure
- `2` - Test failure
- `3` - Wheel build failure

### Test Validation Strategy

**Primary approach: Exit code with documented deselects**

The preferred approach is to deselect known platform-specific failures and rely on pytest's exit code (0 = pass, non-zero = fail). This provides a clear true/false result.

```bash
custom_test_command() {
    # ... setup ...

    # Deselect known platform-specific failures (document each one!)
    pytest \
        -o "addopts=" \
        -k "not test_platform_specific and not test_timing_sensitive" \
        --disable-warnings
}
```

**Key principle**: Every deselected test should be documented with a reason. Create a `test_summary.md` alongside the build script explaining:
- What tests are skipped
- Why they fail on this platform
- Risk assessment (edge case vs. core functionality)

This maintains a binary pass/fail while being transparent about what's excluded.

**Alternative: Pass rate validation**

For exploratory builds or when deselect lists aren't yet established, you can parse pytest's summary line to calculate pass rate:

```bash
custom_test_command() {
    # Capture output while preserving exit behavior
    pytest ... 2>&1 | tee /tmp/pytest_output.txt
    local pytest_exit=${PIPESTATUS[0]}

    # Parse summary line: "= 7 failed, 2518 passed, ... ="
    if summary=$(grep -oE "[0-9]+ failed, [0-9]+ passed" /tmp/pytest_output.txt); then
        failed=$(echo "$summary" | grep -oE "^[0-9]+")
        passed=$(echo "$summary" | grep -oE "[0-9]+ passed" | grep -oE "^[0-9]+")
        total=$((failed + passed))
        pass_rate=$((100 * passed / total))

        log_info "Test pass rate: ${pass_rate}% (${passed}/${total})"

        # Threshold check (e.g., 98%)
        if [[ $pass_rate -ge 98 ]]; then
            log_info "Pass rate acceptable, reviewing failures for platform issues"
            return 0
        fi
    fi

    return $pytest_exit
}
```

**When to use pass rate**: Only during initial porting to identify which tests need investigation. Once you understand the failures, convert to explicit deselects with documentation.

**Warning**: Don't use pass rate thresholds in production - they can mask legitimate regressions hidden in the "acceptable" failure percentage.

---

## Checklist

### Before Starting
- [ ] Read the legacy script completely
- [ ] Check the upstream repo for build requirements
- [ ] Identify Makefile targets, pyproject.toml, setup.py

### Metadata
- [ ] SCRIPT_DIR set correctly
- [ ] PACKAGE_NAME matches repo/package
- [ ] PACKAGE_VERSION has sensible default
- [ ] PACKAGE_URL is correct (no .git suffix required)

### Dependencies
- [ ] RH_DEP_PKGS converted from yum packages
- [ ] DEB_DEP_PKGS has Debian equivalents
- [ ] SLES_DEP_PKGS has SUSE equivalents (optional but recommended)
- [ ] Removed: cmake, make, gcc IF provided by container
- [ ] Kept: -devel packages for C extensions

### Callbacks
- [ ] Cython packages: pre_build() runs cython explicitly
- [ ] Submodules: post_clone() if extra steps needed
- [ ] Code generation: post_clone() or pre_build()
- [ ] Test deselects: custom_test_command() with documentation
- [ ] Complex builds: custom_install() only if necessary

### Removed from Legacy
- [ ] Rust installation (container provides)
- [ ] Node installation (container provides)
- [ ] System package removal (venv isolation)
- [ ] Manual git clone/checkout (template handles)
- [ ] Exit code echo statements (template handles)

### Final
- [ ] Script ends with source line
- [ ] All callbacks defined BEFORE source line
- [ ] Tested with default version
- [ ] Tested with at least one other version

---

## Example: Full Complex Conversion

### Legacy (aiohttp)
```bash
#!/bin/bash -e
PACKAGE_NAME=aiohttp
PACKAGE_VERSION=${1:-v3.9.0}
PACKAGE_URL=https://github.com/aio-libs/aiohttp.git

yum install -y git gcc gcc-c++ make openssl-devel python3-devel python3-pip npm

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init

curl https://sh.rustup.rs -sSf | sh -s -- -y  # Container has rust
source "$HOME/.cargo/env"

pip3 install cython attrs multidict ...
make

pip3 install .

pytest --deselect tests/test_imports.py -k "not test_flaky" --disable-warnings
```

### New (aiohttp)
```bash
#!/bin/bash -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PACKAGE_NAME="aiohttp"
PACKAGE_VERSION="${1:-v3.9.0}"
PACKAGE_URL="https://github.com/aio-libs/aiohttp"

RH_DEP_PKGS="git openssl-devel bzip2-devel libffi-devel zlib-devel libjpeg-devel python3-devel python3-pip"
DEB_DEP_PKGS="git libssl-dev libbz2-dev libffi-dev zlib1g-dev libjpeg-dev python3-dev python3-pip python3-venv"
SLES_DEP_PKGS="git libopenssl-devel libbz2-devel libffi-devel zlib-devel libjpeg-devel python3-devel python3-pip"

post_clone() {
    log_info "Generating llhttp..."
    if [[ -d "vendor/llhttp" ]]; then
        (cd vendor/llhttp && npm install && npm run build)
    fi
}

pre_build() {
    # multidict needed by tools/gen.py
    pip install cython multidict
    # Generate _headers.pxi and _find_header.c from hdrs.py
    if ! python tools/gen.py; then
        log_error "Failed to generate headers"
        return 1
    fi
    # Then run cython from package dir
    if ! (cd aiohttp && cython -3 *.pyx); then
        log_error "Failed to run cython"
        return 1
    fi
}

custom_test_command() {
    pip install -r requirements/test.txt || true
    pip install pytest-mock freezegun trustme || true
    pip install --upgrade "pytest>=7.0" || true

    # Remove plugins that crash during entrypoint loading
    pip uninstall -y pytest-cov pytest-xdist pytest-codspeed 2>/dev/null || true

    # Clear addopts from setup.cfg (may include --cov flags)
    pytest \
        -o "addopts=" \
        --deselect tests/test_imports.py \
        -k "not test_no_warnings and not test_expires and not test_c_parser_loaded" \
        --disable-warnings
}

source "${SCRIPT_DIR}/../../templates/python.sh"
```

---

## LLM-Specific Instructions

When porting scripts as an LLM:

1. **Always read the legacy script first** - understand what it does
2. **Check upstream repo** - look at pyproject.toml, Makefile, requirements/
3. **Start simple** - try without callbacks first
4. **Add callbacks incrementally** - one at a time as needed
5. **Document test deselects** - explain WHY tests are skipped
6. **Preserve comments** - keep the header/disclaimer from original
7. **Ask about unknowns** - if build process is unclear, ask

### Red Flags to Watch For
- `curl ... | sh` (installing tools - probably not needed)
- `pip install` outside venv (should use callbacks)
- Complex Makefile targets (may need custom_install)
- `*.pyx` files (need cython in pre_build)
- `vendor/` or `third_party/` directories (may need post_clone setup)
- Platform-specific code (document in comments)
