# Build Script Guide for IBM Power

A guide for open source developers writing build scripts to port packages to IBM Power architecture.

## Overview

This framework provides language-specific templates that handle the common build workflow for you. Your job is to:

1. **Define your package** (name, version, git URL)
2. **List dependencies** (system packages needed to build)
3. **Customize if needed** (patches, special build steps)

The templates handle everything else: OS detection, package installation, cloning, building, testing, and reporting results to the automation system.

---

## Quick Start

### 1. Choose Your Starter Template

Copy the appropriate starter file for your language:

| Language   | Starter Template        |
|------------|-------------------------|
| Python     | `python_starter.sh`     |
| Java       | `java_starter.sh`       |
| Go         | `go_starter.sh`         |
| Node.js    | `node_starter.sh`       |
| Ruby       | `ruby_starter.sh`       |
| PHP        | `php_starter.sh`        |
| R          | `r_starter.sh`          |

### 2. Fill In Required Fields

Every build script needs these three pieces of information:

```bash
PACKAGE_NAME="your-package"
PACKAGE_VERSION="${1:-v1.0.0}"    # First argument, or default version
PACKAGE_URL="https://github.com/owner/repo"
```

### 3. Specify Dependencies

List the system packages your build needs:

```bash
RH_DEP_PKGS="git python3 python3-devel gcc"      # Red Hat/UBI/Fedora
DEB_DEP_PKGS="git python3 python3-dev gcc"       # Debian/Ubuntu
SLES_DEP_PKGS="git python3 python3-devel gcc"    # SUSE
```

### 4. Source the Template

The last line runs the build:

```bash
source "${SCRIPT_DIR}/../../python.sh"
```

### 5. Run It

```bash
./your_package.sh v1.2.3
```

---

## Minimal Example (Python)

For packages with no special requirements:

```bash
#!/bin/bash -e
# Package: python-fire
# Source:  https://github.com/google/python-fire

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PACKAGE_NAME="python-fire"
PACKAGE_VERSION="${1:-v0.7.0}"
PACKAGE_URL="https://github.com/google/python-fire"

RH_DEP_PKGS="git python3 python3-devel python3-pip gcc"
DEB_DEP_PKGS="git python3 python3-dev python3-pip python3-venv gcc"
SLES_DEP_PKGS="git python3 python3-devel python3-pip gcc"

source "${SCRIPT_DIR}/../../python.sh"
```

That's it. The template handles cloning, building, finding tests, and running them.

---

## Customizing Builds with Callbacks

When packages need special handling, define callback functions **before** the `source` line.

### Available Callbacks

| Callback              | When It Runs                          | Common Uses                         |
|-----------------------|---------------------------------------|-------------------------------------|
| `pre_packages()`      | Before installing system packages     | Add extra package repositories      |
| `pre_clone()`         | Before git clone                      | Set environment variables           |
| `post_clone()`        | After checkout                        | Apply patches, modify source        |
| `pre_build()`         | Before build starts                   | Install extra pip/npm dependencies  |
| `post_build()`        | After build, before tests             | Verify installation                 |
| `custom_test_command()` | Replaces default test logic         | Run specific test suite             |
| `post_test()`         | After tests complete                  | Cleanup, collect artifacts          |
| `custom_install()`    | Replaces entire install logic         | Non-standard build systems          |

### Example: Applying a Patch

```bash
post_clone() {
    # Fix a Power-specific issue
    sed -i 's/x86_64/ppc64le/g' setup.py

    # Or apply a patch file
    git apply "${SCRIPT_DIR}/patches/power-fix.patch"
}
```

### Example: Custom Test Suite

```bash
custom_test_command() {
    # Run only unit tests, skip integration
    python -m pytest tests/unit/ -x --timeout=300
}
```

### Example: Extra Build Dependencies

```bash
pre_build() {
    pip install cython numpy
    export CFLAGS="-O2"
}
```

### Example: Verify Installation

```bash
post_build() {
    python -c "import mypackage; print(mypackage.__version__)"
}
```

---

## Language-Specific Notes

### Python

**Build tools supported:** pip, setup.py, pyproject.toml

**Test frameworks auto-detected:** pytest, tox, nox

**Optional variables:**
```bash
PYTHON_VERSION="python3"    # Python interpreter to use
SKIP_TESTS="true"           # Skip test phase
NOARCH="true"               # Install from PyPI instead of building
PYPI_NAME="package-name"    # PyPI name if different from PACKAGE_NAME
```

### Java

**Build tools supported:** Maven (pom.xml), Gradle (build.gradle), Ant (build.xml)

**JDK versions:** Auto-tries 11, 17, 21

**Optional variables:**
```bash
JAVA_VERSION="17"           # Force specific JDK version
BUILD_TOOL="maven"          # Force build tool selection
```

### Go

**Build:** Standard `go build`

**Test:** `go test ./...`

**Optional variables:**
```bash
GO_VERSION="1.23.4"         # Go version to install
```

### Node.js

**Build:** `npm install` or `yarn install`

**Test:** `npm test`

**Optional variables:**
```bash
NODE_VERSION="20"           # Node.js major version
```

### Ruby

**Build:** `bundle install` and `gem build`

**Test:** `bundle exec rspec` or `bundle exec rake test`

**Optional variables:**
```bash
RUBY_VERSION="3.2.0"        # Ruby version (uses rbenv)
```

### PHP

**Build:** `composer install`

**Test:** `./vendor/bin/phpunit`

### R

**Build:** `R CMD build` and `R CMD INSTALL`

**Test:** `R CMD check`

**Optional variables:**
```bash
SKIP_VIGNETTES="true"       # Skip vignette building
CRAN_DEPS="true"            # Auto-install CRAN dependencies
```

---

## Dependencies Reference

### Common Python Packages

```bash
# Basic Python build
RH_DEP_PKGS="git python3 python3-devel python3-pip gcc"

# With native extensions (crypto, compression)
RH_DEP_PKGS="git python3 python3-devel python3-pip gcc gcc-c++ openssl-devel libffi-devel zlib-devel"

# With XML/database support
RH_DEP_PKGS="git python3 python3-devel python3-pip gcc libxml2-devel libxslt-devel postgresql-devel"
```

### Common Java Packages

```bash
# Full JDK support
RH_DEP_PKGS="git gcc gcc-c++ make wget tar java-11-openjdk java-11-openjdk-devel java-17-openjdk java-17-openjdk-devel java-21-openjdk java-21-openjdk-devel ant"
```

### Common Go Packages

```bash
# Go builds (Go is installed by template)
RH_DEP_PKGS="git gcc gcc-c++ make wget"
```

### Common Node.js Packages

```bash
# Node with native addon support
RH_DEP_PKGS="git python3 python3-devel gcc gcc-c++ make"
```

---

## Exit Codes

The automation system expects these exit codes:

| Code | Meaning                                    |
|------|--------------------------------------------|
| 0    | Success (build and tests passed)           |
| 1    | Build/Install failure                      |
| 2    | Test failure (build succeeded)             |

You don't need to handle these yourself - the templates manage exit codes automatically.

---

## Script Header Format

Include this standard header for tracking and documentation:

```bash
#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : your-package-name
# Version       : v1.0.0
# Source repo   : https://github.com/owner/repo
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Your Name <your.email@example.com>
# -----------------------------------------------------------------------------
```

---

## Debugging Tips

### Run with verbose output

```bash
bash -x ./your_package.sh v1.0.0
```

### Check what's happening in callbacks

```bash
post_clone() {
    log_info "Current directory: $(pwd)"
    log_info "Files present: $(ls)"
    # your patch commands...
}
```

The `log_info` function is available in all callbacks for consistent output.

### Test locally before submitting

```bash
# Test with a specific version
./your_package.sh v2.0.0

# Test with default version
./your_package.sh
```

---

## Common Patterns

### Handling Version Formats

Some projects use different tag formats:

```bash
# GitHub uses 'v' prefix
PACKAGE_VERSION="${1:-v1.0.0}"

# Some projects use release/ prefix
PACKAGE_VERSION="${1:-release/1.0.0}"

# Or no prefix at all
PACKAGE_VERSION="${1:-1.0.0}"
```

### Skipping Flaky Tests

```bash
custom_test_command() {
    python -m pytest tests/ --ignore=tests/integration/ -x
}
```

### Building Documentation Separately

```bash
post_build() {
    cd docs && make html
}
```

### Handling Submodules

```bash
post_clone() {
    git submodule update --init --recursive
}
```

### Setting Build Flags

```bash
pre_build() {
    export CFLAGS="-O2 -fPIC"
    export LDFLAGS="-L/usr/local/lib"
}
```

---

## Troubleshooting

### "Package not found" during install

Add the missing package to your `*_DEP_PKGS` variables. Package names differ between distributions:

| Red Hat (UBI)        | Debian/Ubuntu         |
|----------------------|-----------------------|
| python3-devel        | python3-dev           |
| openssl-devel        | libssl-dev            |
| libffi-devel         | libffi-dev            |
| gcc-c++              | g++                   |

### Tests fail but build succeeds

Check if tests require:
- Network access (may be blocked in CI)
- Specific test data
- Extra test dependencies

Use `custom_test_command()` to run a subset of tests or install additional test dependencies.

### Clone fails with "tag not found"

Verify the exact tag/version format in the upstream repository:
```bash
git ls-remote --tags https://github.com/owner/repo
```

### Build works locally but fails in CI

Common causes:
- Missing dependencies in `*_DEP_PKGS`
- Tests that need display/GUI (use `xvfb-run` if needed)
- Hardcoded paths or architecture assumptions

---

## File Structure

Your build script should be placed alongside other scripts in your package directory:

```
your-package/
    your_package.sh          # Your build script
    patches/                 # Optional: patch files
        power-fix.patch
```

---

## Getting Help

- Check existing build scripts in the repository for similar packages
- Review the starter template comments for your language
- Test your script locally before submission
