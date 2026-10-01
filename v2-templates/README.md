# Build Script Templates

Standardized build script templates for multiple programming languages with common shared libraries.

## Quick Start

User scripts define metadata and source the template - minimal boilerplate:

```bash
#!/bin/bash -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Required: Package metadata
PACKAGE_NAME="python-fire"
PACKAGE_VERSION="${1:-v0.7.0}"
PACKAGE_URL="https://github.com/google/python-fire"
PROVIDES_ARTIFACT="python-fire"

# Required: Dependencies
RH_DEP_PKGS="git python3 python3-devel python3-pip gcc"
DEB_DEP_PKGS="git python3 python3-dev python3-pip python3-venv gcc"

# Execute the build (template handles everything)
source "${SCRIPT_DIR}/../../templates/python.sh"
```

See `examples/python_starter.sh` for a ready-to-use starter template.

## Directory Structure

```
templates/
├── lib/                              # Common include libraries
│   ├── common.sh                     # Core functions and variables
│   ├── distro-packages.sh            # Multi-distro package installation
│   ├── automation-stanzas.sh         # CI/CD output functions
│   ├── artifacts.sh                  # Artifact management
│   ├── container.sh                  # Container image building (multi-arch)
│   ├── prereq-checks.sh              # Prerequisite checking functions
│   ├── docker-build.sh               # Docker container build helpers
│   └── wheel-utils.sh                # Python wheel utilities
├── base.sh                           # Base template for native C/C++ builds
├── python.sh                         # Python template
├── node.sh                           # Node.js template
├── go.sh                             # Go template
├── java.sh                           # Java template (Maven/Gradle/Ant)
├── ruby.sh                           # Ruby template
├── php.sh                            # PHP template
├── r.sh                              # R template
├── fallback/                         # Automation fallback templates
│   ├── python_starter.sh             # Used by container system for auto-builds
│   ├── node_starter.sh               # Attempts build with minimal config
│   ├── go_starter.sh                 # (system provides PACKAGE_NAME, VERSION, URL)
│   ├── java_starter.sh
│   ├── ruby_starter.sh
│   ├── php_starter.sh
│   └── r_starter.sh
├── examples/                         # User-facing example scripts
│   ├── python_starter.sh             # Copy and customize for new packages
│   ├── python_simple_example.sh      # Simple package (no callbacks)
│   ├── python_with_callbacks_example.sh # Package with hooks
│   ├── node_starter.sh
│   ├── go_starter.sh
│   ├── java_starter.sh
│   ├── ruby_starter.sh
│   ├── php_starter.sh
│   ├── r_starter.sh
│   └── package_with_native_deps.sh   # Native dependencies example
├── docs/                             # Additional documentation
│   ├── PORTING_GUIDE.md              # Migration guide
│   ├── NATIVE_DEPENDENCIES.md        # Native library handling
│   ├── ARTIFACT_SYSTEM_IMPLEMENTATION.md
│   └── CONTAINER_PUBLISH.md          # Container build guide
└── template-tools/                   # Migration and analysis tools
```

### fallback/ vs examples/

- **fallback/**: Used by the automated container build system. When building a new package, the system provides minimal variables (PACKAGE_NAME, VERSION, URL) and tries these templates to see if the build "just works" without custom configuration.

- **examples/**: For human users to copy into their package directories and customize. More verbose with comments and documentation.

## Common Include Libraries

All templates source these libraries from `lib/`:

### lib/common.sh
Core variables and functions:
- `detect_os()` - Populates OS_NAME, OS_ID, OS_VERSION
- `validate_required_vars()` - Check required variables are set
- `log_info()`, `log_warn()`, `log_error()` - Logging functions
- `output_status()` - Write to VERSION_TRACKER file (if set) and stdout

### lib/distro-packages.sh
Multi-distro package installation:
- `install_packages()` - Install packages based on detected OS
- Supports: Red Hat (dnf/yum), Debian (apt-get), SUSE (zypper)
- Uses `RH_DEP_PKGS`, `DEB_DEP_PKGS`, `SLES_DEP_PKGS` variables

### lib/automation-stanzas.sh
CI/CD reporting functions:
- `report_clone_fail()` - Exit 1 on clone failure
- `report_install_fail()` - Exit 1 on install failure
- `report_build_fail()` - Exit 1 on build failure
- `report_test_fail()` - Exit 2 on test failure
- `report_success()` - Exit 0 on full success
- `report_no_tests()` - Exit 0 when no tests available

### lib/artifacts.sh
Artifact management for build dependencies:
- `artifact_dir()` - Get artifact installation directory
- `source_artifact()` - Source an artifact's activation script
- `PROVIDES_ARTIFACT` - Artifact name this package provides
- `BUILD_DEPS` - Space-separated artifact dependencies

### lib/container.sh
Container image building with multi-arch support:
- `build_container()` - Build container with buildah
- `manifest_create()` - Create multi-arch manifest
- `manifest_push()` - Push manifest to registry
- See `docs/CONTAINER_PUBLISH.md` for details

### lib/prereq-checks.sh
Prerequisite checking:
- `check_command()` - Check if command exists
- `check_rpm_package()` / `check_deb_package()` - Check installed packages
- `check_service_running()` - Check systemd service status
- `check_file_exists()` / `check_dir_exists()` - File checks
- `check_ownership()` - Verify file ownership
- `check_is_root()` / `check_has_sudo()` - Permission checks

### lib/wheel-utils.sh
Python wheel building utilities for multi-version builds.

## Environment Variables

### Common Variables
| Variable | Description | Default |
|----------|-------------|---------|
| `VERSION_TRACKER` | Output file for automation | (stdout only) |
| `PYTHON_VERSION` | Python interpreter to use | `python3` |
| `NODE_VERSION` | Node.js version (nvm) | `20` |
| `GO_VERSION` | Go version | `1.23.4` |
| `RUBY_VERSION` | Ruby version (rbenv) | `3.2.0` |
| `PHP_VERSION` | PHP version | `8.2` |
| `JAVA_VERSION` | JDK version preference | (auto-detect) |

### Artifact Variables
| Variable | Description |
|----------|-------------|
| `PROVIDES_ARTIFACT` | Artifact name this build provides |
| `BUILD_DEPS` | Space-separated artifact dependencies |
| `ARTIFACT_DIR` | Base directory for artifacts (default: `/opt/artifacts`) |

### Container Variables
| Variable | Description |
|----------|-------------|
| `BUILD_CONTAINER` | Set to `1` to build container image |
| `CONTAINER_REGISTRY` | Registry for tagging (e.g., `icr.io/namespace`) |
| `CONTAINER_PUSH` | Set to `1` to push after build |

### Automation Mode
Set `VERSION_TRACKER` to enable automation output:
```bash
VERSION_TRACKER=/path/to/output.txt ./mypackage.sh v1.0.0
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success (install + test passed, or install passed with no tests) |
| 1 | Clone, download, or install failure |
| 2 | Test failure (install succeeded) |

## Callback Hooks

Templates support callback functions for customization without modifying the template itself.

### Available Callbacks

| Callback | When Called | Use Case |
|----------|-------------|----------|
| `pre_packages()` | Before package install | Add extra repos (EPEL, RHSCL, etc.) |
| `pre_clone()` | Before git clone | Extra system setup, environment variables |
| `post_clone()` | After checkout | Apply patches, modify source files |
| `pre_build()` | Before pip/npm install | Install extra pip dependencies, set flags |
| `post_build()` | After install, before test | Verify installation, collect artifacts |
| `custom_test_command()` | Instead of default tests | Override pytest/npm test/go test |
| `post_test()` | After tests pass | Cleanup, coverage collection |
| `custom_install()` | Instead of default install | Completely custom build logic |

### Example: Applying Patches

```bash
#!/bin/bash -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PACKAGE_NAME="my-package"
PACKAGE_VERSION="${1:-v1.0.0}"
PACKAGE_URL="https://github.com/org/my-package"
PROVIDES_ARTIFACT="my-package"

RH_DEP_PKGS="git python3 python3-devel python3-pip gcc"
DEB_DEP_PKGS="git python3 python3-dev python3-pip python3-venv gcc"

# Apply patches after cloning
post_clone() {
    git apply "${SCRIPT_DIR}/patches/fix-build.patch"
    sed -i 's/old_api/new_api/g' src/module.py
}

source "${SCRIPT_DIR}/../../templates/python.sh"
```

### Example: Custom Test Command

```bash
# Override default pytest with custom options
custom_test_command() {
    python -m pytest tests/unit/ -x --timeout=300 -v
}
```

### Example: Adding Extra Repos

```bash
# Enable EPEL or other repos before package install
pre_packages() {
    sudo dnf install -y epel-release
    sudo dnf config-manager --set-enabled crb
}
```

### Example: Extra Build Dependencies

```bash
# Install extra pip packages before building
pre_build() {
    pip install cython numpy
    export CFLAGS="-O2"
}
```

### Callback Order

```
1. pre_packages()        # Add extra repos
2. [install_packages]    # System packages
3. pre_clone()           # Before git clone
4. [git clone]           # Clone repository
5. post_clone()          # After checkout
6. pre_build()           # Before install
7. [pip install / custom_install()]
8. post_build()          # After install
9. [custom_test_command() or default tests]
10. post_test()          # After tests
11. [report results]
```

## Creating New Scripts

### For Simple Packages (Most Common)

1. Copy `examples/python_starter.sh` to your package directory
2. Replace the placeholder values
3. Run and test

### For Packages Needing Patches

1. Copy `examples/python_starter.sh`
2. Add a `post_clone()` function with your patch logic

### For Native C/C++ Libraries

1. Use `base.sh` instead of language-specific templates
2. Set `BUILD_SYSTEM` to `autoconf`, `cmake`, `meson`, or `make`
3. Use `CONFIGURE_OPTS`, `CMAKE_OPTS`, etc. for build options

### For Container Builds

1. Create a `Dockerfile` in the package directory
2. Set `BUILD_CONTAINER=1` in the script
3. Optionally set `CONTAINER_REGISTRY` for tagging

## Multi-Distro Support

Templates auto-detect and support:

| Family | Distributions | Package Manager |
|--------|---------------|-----------------|
| Red Hat | RHEL 9, Fedora, UBI 9, CentOS Stream | dnf |
| Red Hat Legacy | RHEL 7/8, CentOS 7 | yum |
| Debian | Ubuntu, Debian | apt-get |
| SUSE | SLES, openSUSE | zypper |

## Python Best Practices

Python templates use virtual environments:
- `.venv-build` - Build environment with pip, build, wheel
- `.venv-test` - Clean test environment with pytest

```bash
# Set Python version for automation
PYTHON_VERSION=python3.11 ./mypackage.sh v1.0.0
```

## Target Platform

All templates target **UBI 9 / RHEL 9** on **ppc64le**. Scripts for older platforms should be migrated to current templates.

## Sudo Requirements

Templates use `sudo` for package installation when dependencies are missing.
For non-root execution with pre-installed dependencies, no sudo is needed.

See `template-tools/sudoers.d_builder` for sudoers configuration.
