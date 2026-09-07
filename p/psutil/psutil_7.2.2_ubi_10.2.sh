#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : psutil
# Version          : release-7.2.2
# Source repo      : https://github.com/giampaolo/psutil.git
# Tested on        : ubi:10.2
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Yogita Kulkarni <Yogita.Kulkarni@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

set -e

PACKAGE_NAME=psutil
PACKAGE_VERSION=${1:-release-7.2.2}
PACKAGE_URL=https://github.com/giampaolo/psutil.git
PACKAGE_DIR=psutil
CURRENT_DIR=$(pwd)
# Normalise: if we are at filesystem root, avoid double-slash paths.
[[ "$CURRENT_DIR" == "/" ]] && CURRENT_DIR=""

# Install system dependencies.
# Python packages must come first (wrapper strips them for venv re-installs).
yum install -y python3.14 python3.14-devel python3.14-pip \
    git gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ \
    make openssl-devel bzip2-devel libffi-devel zlib-devel procps-ng

# UBI 10 dropped SCL — activate gcc-toolset-15 via PATH export.
if [[ -f /opt/rh/gcc-toolset-15/enable ]]; then
    source /opt/rh/gcc-toolset-15/enable
elif [[ -d /opt/rh/gcc-toolset-15/root/usr/bin ]]; then
    export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"
    export LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64:$LD_LIBRARY_PATH"
else
    echo "ERROR: gcc-toolset-15 not found"
    exit 1
fi

echo "Using gcc: $(gcc --version | head -1)"

# Upgrade pip and install build tools.
python3.14 -m pip install --upgrade pip setuptools wheel build

# Clone and checkout.
cd "$CURRENT_DIR"
rm -rf "$PACKAGE_DIR"
git clone "$PACKAGE_URL" "$PACKAGE_DIR"
cd "$PACKAGE_DIR"

if git rev-parse "${PACKAGE_VERSION}" &>/dev/null; then
    git checkout "${PACKAGE_VERSION}"
elif git rev-parse "v${PACKAGE_VERSION}" &>/dev/null; then
    git checkout "v${PACKAGE_VERSION}"
else
    echo "ERROR: No git tag found for version '${PACKAGE_VERSION}'"
    exit 1
fi

# Install test dependencies.
python3.14 -m pip install pytest pytest-instafail pytest-xdist psleak

# Build and install.
if ! python3.14 -m pip install --no-build-isolation .; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Build wheel and copy to CURRENT_DIR for CI wrapper / auditwheel.
python3.14 -m build --wheel --no-isolation --outdir="$CURRENT_DIR/"

# Set test environment variables.
export PYTHONWARNINGS=always
export PYTHONUNBUFFERED=1
export PSUTIL_DEBUG=1
export PSUTIL_TESTING=1
export PYTEST_DISABLE_PLUGIN_AUTOLOAD=1

# Run tests from a neutral directory outside the source tree so that Python
# does not shadow the installed psutil wheel with the local source psutil/ dir.
TESTS_DIR="$(pwd)/tests"
TMPDIR=$(mktemp -d)
cp -r "$TESTS_DIR" "$TMPDIR/"
cd "$TMPDIR"
if ! python3.14 -m pytest tests/ -v \
        --import-mode=importlib \
        --deselect=tests/test_linux.py \
        --deselect=tests/test_system.py \
        --deselect=tests/test_memleaks.py \
        --deselect=tests/test_scripts.py \
        -k "not test_disk_partitions and not test_debug and not test_who \
            and not test_terminal and not test_users and not test_cpu_freq \
            and not test_leak_mem and not test_cpu_affinity and not test_cpu_times \
            and not test_per_cpu_times and not test_import_all \
            and not test_multi_sockets_procs and not test_against_nproc \
            and not test_against_sysdev_cpu_num and not test_against_findmnt \
            and not test_comparisons" \
        --disable-warnings; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
