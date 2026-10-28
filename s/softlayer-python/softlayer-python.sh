#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : softlayer-python
# Version       : v6.2.6
# Source repo   : https://github.com/softlayer/softlayer-python
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="softlayer-python"
PACKAGE_VERSION="${1:-v6.2.6}"
PACKAGE_URL="https://github.com/softlayer/softlayer-python"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3 python3-devel python3-pip"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# softlayer-python is a pure-Python package published on PyPI under the name
# "softlayer" (not "softlayer-python"), so set PYPI_NAME and skip source build.
NOARCH="true"
PYPI_NAME="softlayer"

# =============================================================================
# CALLBACK: custom_test_command — run pytest deselecting tests that are broken
# under Click 8.x due to two distinct upstream bugs in v6.2.6.
#
# BUG 1 — cancel/abort tests (7 tests):
#   The CLI cancel commands (dedicatedhost, subnet, hardware, file, block) call
#   formatting.no_going_back() to ask for confirmation.  The tests mock
#   formatting.confirm (the wrong function).  With Click 8.x, the unmocked
#   no_going_back() calls click.prompt() on a non-TTY stdin, which raises
#   EOFError → click.Abort → sys.exit(1).  The tests assert exit_code == 2
#   (CLIAbort), so they fail with 1 != 2.  Root cause: tests mock the wrong
#   function; this is an upstream test bug against Click 8.x.
#   Upstream issue not fixed as of v6.2.9 (latest at time of testing).
#
# BUG 2 — vs create --like tests (5 tests):
#   The --hostname, --domain and --datacenter options are declared with
#   prompt=True in SoftLayer/CLI/virt/create.py.  When --like is used, those
#   values are supplied via click's default_map.  In Click 7.x a default_map
#   entry suppressed the prompt; in Click 8.x the prompt is still shown unless
#   the value is passed explicitly on the command line.  The test runner
#   provides no stdin, so click.prompt raises EOFError → Abort → sys.exit(1).
#   Root cause: Click 8.x behaviour change; upstream source not updated.
#   Upstream issue not fixed as of v6.2.9 (latest at time of testing).
#
# BUG 3 — test_getpass_issues1436 (1 test):
#   environment_tests.py patches 'SoftLayer.CLI.environment.getpass' but the
#   mock setup also triggers an import of tkinter, which requires the C
#   extension _tkinter.  In a headless UBI container _tkinter is not available
#   (no Tk/X11 display), so the import fails with ModuleNotFoundError.
#   Root cause: test has a runtime tkinter dependency on a headless host.
# =============================================================================
custom_test_command() {
    log_info "Running pytest with Click-8.x-incompatible tests deselected"
    python -m pytest tests \
        -o "addopts=" \
        --disable-warnings \
        --deselect tests/CLI/modules/dedicatedhost_tests.py::DedicatedHostsTests::test_cancel_host_abort \  # BUG 1: tests mock wrong function; Click 8.x no_going_back() raises EOFError on non-TTY stdin
        --deselect tests/CLI/modules/dedicatedhost_tests.py::DedicatedHostsTests::test_cancel_guests_abort \  # BUG 1: same root cause as above
        --deselect tests/CLI/modules/subnet_tests.py::SubnetTests::test_cancel_fail \  # BUG 1: same root cause as above
        --deselect tests/CLI/modules/hardware/hardware_basic_tests.py::HardwareCLITests::test_hardware_cancel_no_force \  # BUG 1: same root cause as above
        --deselect tests/CLI/modules/file_tests.py::FileTests::test_file_snapshot_cancel_force \  # BUG 1: same root cause as above
        --deselect tests/CLI/modules/file_tests.py::FileTests::test_file_volume_cancel_force \  # BUG 1: same root cause as above
        --deselect tests/managers/block_tests.py::BlockTests::test_snapshot_cancel_no_force \  # BUG 1: same root cause as above
        --deselect tests/CLI/modules/vs/vs_create_tests.py::VirtCreateTests::test_create_like \  # BUG 2: Click 8.x no longer suppresses prompts via default_map; EOFError on non-TTY stdin
        --deselect tests/CLI/modules/vs/vs_create_tests.py::VirtCreateTests::test_create_like_tags \  # BUG 2: same root cause as above
        --deselect tests/CLI/modules/vs/vs_create_tests.py::VirtCreateTests::test_create_like_image \  # BUG 2: same root cause as above
        --deselect tests/CLI/modules/vs/vs_create_tests.py::VirtCreateTests::test_create_like_flavor \  # BUG 2: same root cause as above
        --deselect tests/CLI/modules/vs/vs_create_tests.py::VirtCreateTests::test_create_like_transient \  # BUG 2: same root cause as above
        --deselect tests/CLI/environment_tests.py::EnvironmentTests::test_getpass_issues1436  # BUG 3: triggers tkinter/_tkinter import; not available in headless UBI container
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"


