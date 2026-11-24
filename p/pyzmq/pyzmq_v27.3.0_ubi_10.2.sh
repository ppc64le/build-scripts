#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : pyzmq
# Version          : v27.3.0
# Source repo      : https://github.com/zeromq/pyzmq
# Tested on        : UBI:10.2
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Veenious D Geevarghese <Veenious.Geevarghese@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

# Variables
PACKAGE_NAME=pyzmq
SCRIPT_PACKAGE_VERSION=v27.3.0
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
PACKAGE_URL=https://github.com/zeromq/pyzmq
PACKAGE_DIR=pyzmq

BUILD_HOME=$(pwd)
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

# Install dependencies
yum install -y git \
    cmake make wget openssl-devel bzip2-devel glibc-static libstdc++-static libffi-devel \
    zlib-devel python3-devel python3-pip pkg-config automake autoconf libtool

yum install -y gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ gcc-toolset-15-gcc-gfortran

# ---------------------------------------------------------------------------
# Activate GCC Toolset 15 (SCL removed in UBI 10 — use PATH export)
# ---------------------------------------------------------------------------
if [[ -f /opt/rh/gcc-toolset-15/enable ]]; then
    source /opt/rh/gcc-toolset-15/enable
elif [[ -d /opt/rh/gcc-toolset-15/root/usr/bin ]]; then
    export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"
    export LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64:${LD_LIBRARY_PATH:-}"
else
    echo "ERROR: gcc-toolset-15 not found"
    exit 1
fi

export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"
export LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64:${LD_LIBRARY_PATH:-}"

export CC="/opt/rh/gcc-toolset-15/root/usr/bin/gcc"
export CXX="/opt/rh/gcc-toolset-15/root/usr/bin/g++"

# Detect CPU generation and set optimization flags accordingly
if grep -iq "POWER10" /proc/cpuinfo 2>/dev/null; then
    CPU_FLAGS="-mcpu=power10 -mtune=power10"
    echo "Detected POWER10 — applying power10 optimization flags"
else
    CPU_FLAGS=""
    echo "POWER10 not detected — no arch-specific flags applied"
fi

# Apply CPU optimization flags (picked up by scikit-build-core/CMake when building the
# extension and the bundled libzmq)
export CFLAGS="${CPU_FLAGS}"
export CXXFLAGS="${CPU_FLAGS}"

# Clone the repository
rm -rf "$PACKAGE_DIR"
if ! git clone "$PACKAGE_URL" "$PACKAGE_DIR"; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Clone_Fails"
    exit 1
fi
cd "$PACKAGE_DIR"
git checkout "$PACKAGE_VERSION"
echo "Resolved commit: $(git rev-parse HEAD)"

# Install python build/test dependencies
# (build-system.requires in pyproject.toml: cython>=3.0.0, packaging, scikit-build-core>=0.10)
python3 -m pip install cython==3.0.12 packaging==24.2 pathspec==0.12.1 scikit-build-core==0.11.1 \
    cmake==3.27.9 ninja==1.11.1.4 build pytest pytest-asyncio pytest-timeout pytest-rerunfailures

# Install
if ! python3 -m pip install -e . ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi

# Run tests (draft and cython tests are excluded: they need libzmq draft APIs / a cython build env)
if ! python3 -m pytest -v --timeout=60 --capture=no -p no:warnings \
    --ignore=tests/test_draft.py --ignore=tests/test_cython.py ; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Both_Install_and_Test_Success"
fi

# Building wheel with script itself as it needs to locate the libzmq target file
if ! python3 -m build --wheel --no-isolation --outdir="$BUILD_HOME"; then
    echo "------------------$PACKAGE_NAME: Wheel Build Failed ---------------------"
    exit 2
fi
echo "------------------$PACKAGE_NAME: Wheel Build Success -------------------------"

WHEEL_FILE=$(find "$BUILD_HOME" -maxdepth 1 -name "pyzmq-*.whl" | head -1)
if [ -z "$WHEEL_FILE" ]; then
    echo "------------------$PACKAGE_NAME:Wheel_build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Wheel_Build_Fails"
    exit 1
fi

# Install the wheel in a clean venv
python3 -m venv /tmp/pyzmq-test-env
source /tmp/pyzmq-test-env/bin/activate
if ! pip install --force-reinstall "$WHEEL_FILE"; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    deactivate
    exit 1
fi

# Smoke test - run from /tmp so Python imports the installed wheel, not the
# source tree.
cd /tmp
if ! python3 -c "
from importlib.metadata import version
import zmq
print('pyzmq', version('pyzmq'), '| libzmq', zmq.zmq_version(), '|', zmq.__file__)
assert version('pyzmq') == '${PACKAGE_VERSION#v}'
"; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_test_Fails"
    cd "$BUILD_HOME"
    exit 2
fi
cd "$BUILD_HOME"
deactivate

echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Both_Install_and_Test_Success"
exit 0
