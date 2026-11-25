#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : jupyter_enterprise_gateway
# Version       : v3.2.2
# Source repo   : https://github.com/jupyter-server/enterprise_gateway
# Tested on     : UBI:10.2
# Language      : Python
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Veenious D Geevarghese <Veenious.Geevarghese@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=jupyter_enterprise_gateway
SCRIPT_PACKAGE_VERSION=v3.2.2
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
PACKAGE_URL=https://github.com/jupyter-server/enterprise_gateway
PACKAGE_DIR=enterprise_gateway
PYZMQ_VERSION=${PYZMQ_VERSION:-v27.3.0}
PYZMQ_SCRIPT="pyzmq_${PYZMQ_VERSION}_ubi_10.2.sh"
export INDEX_URL_DEVPY=${INDEX_URL_DEVPY:-https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple}

BUILD_HOME=$(pwd)
SCRIPT_PATH=$(dirname "$(realpath "$0")")
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

# Install system dependencies
yum install -y git \
    cmake make wget openssl-devel bzip2-devel glibc-static libstdc++-static libffi-devel \
    zlib-devel python3-devel python3-pip pkg-config automake autoconf libtool rust cargo

yum install -y gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ gcc-toolset-15-gcc-gfortran 2>/dev/null || true

# Activate GCC Toolset 15
if [[ -f /opt/rh/gcc-toolset-15/enable ]]; then
    source /opt/rh/gcc-toolset-15/enable
elif [[ -d /opt/rh/gcc-toolset-15/root/usr/bin ]]; then
    export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"
    export LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64:${LD_LIBRARY_PATH:-}"
fi

# Detect CPU generation and set optimization flags
if grep -iq "POWER10" /proc/cpuinfo 2>/dev/null; then
    CPU_FLAGS="-mcpu=power10 -mtune=power10"
    echo "Detected POWER10 — applying power10 optimization flags"
else
    CPU_FLAGS=""
    echo "POWER10 not detected — no arch-specific flags applied"
fi

export CFLAGS="${CPU_FLAGS}"
export CXXFLAGS="${CPU_FLAGS}"

# Upgrade core python packaging tools
python3 -m pip install --upgrade pip setuptools wheel build hatchling hatch "pytest<9"

# -----------------------------------------------------------------------------
# Call pyzmq build script (Jupyter dependency required on ppc64le)
# -----------------------------------------------------------------------------
echo "-------------------Installing pyzmq from DevFirst portal----------------------"
if python3 -m pip install --only-binary=pyzmq "pyzmq==${PYZMQ_VERSION#v}" --index-url "${INDEX_URL_DEVPY}"; then
    echo "pyzmq wheel installed from DevFirst"
elif [ -f "${SCRIPT_PATH}/../../p/pyzmq/${PYZMQ_SCRIPT}" ]; then
    echo "pyzmq wheel not on DevFirst, building with local ${PYZMQ_SCRIPT}"
    if ! bash "${SCRIPT_PATH}/../../p/pyzmq/${PYZMQ_SCRIPT}" "$PYZMQ_VERSION"; then
        echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
        exit 1
    fi
elif wget -q "https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/p/pyzmq/${PYZMQ_SCRIPT}"; then
    echo "pyzmq wheel not on DevFirst, building with ${PYZMQ_SCRIPT}"
    if ! bash "${PYZMQ_SCRIPT}" "$PYZMQ_VERSION"; then
        echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
        exit 1
    fi
else
    echo "pyzmq wheel not on DevFirst and ${PYZMQ_SCRIPT} does not exist"
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi
cd "$BUILD_HOME"

# Clean up any leftover editable .pth files and reinstall pyzmq wheel cleanly
find /usr/local/lib*/python3*/site-packages/ /usr/lib*/python3*/site-packages/ -name "*_editable_skbc_pyzmq.pth" -delete 2>/dev/null || true
PYZMQ_WHEEL=$(find "$BUILD_HOME" -maxdepth 2 -name "pyzmq-*.whl" 2>/dev/null | head -1)
if [ -n "$PYZMQ_WHEEL" ]; then
    python3 -m pip install --force-reinstall --no-deps "$PYZMQ_WHEEL"
fi

# Clone jupyter_enterprise_gateway repository
cd "$BUILD_HOME"
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

# Install dependencies with test extras (excluding pyzmq cap), then install package with --no-deps
python3 -m pip install --ignore-installed \
    "docker>=3.5.0" "future" "jinja2>=3.1" "jupyter_client>=6.1.12,<7" \
    "jupyter_core>=4.7.0" "kubernetes>=18.20.0" "jupyter_server>=1.3,<2.0" \
    "paramiko>=2.11" "pexpect>=4.8.0" "pycryptodomex>=3.9.7" "requests>=2.14.2" \
    "tornado>=6.1" "traitlets>=5.3.0" "watchdog>=2.1.3" "yarn-api-client>=1.0" \
    "coverage" "pytest<9" "pytest-tornasync" "ipykernel" "websocket-client"

if ! python3 -m pip install --no-deps -e . ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi

# Allow root user to execute kernel operations in test environment
export EG_UNAUTHORIZED_USERS=""

# Run pytest unit tests (ignoring deprecation warnings from legacy zmq.ioloop in jupyter_client 6)
if ! python3 -m pytest -v -W "ignore::DeprecationWarning" enterprise_gateway/tests/ ; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Both_Install_and_Test_Success"
fi

# -----------------------------------------------------------------------------
# Wheel Build & Smoke Test
# -----------------------------------------------------------------------------
if ! python3 -m build --wheel --no-isolation --outdir="$BUILD_HOME"; then
    echo "------------------$PACKAGE_NAME: Wheel Build Failed ---------------------"
    exit 2
fi
echo "------------------$PACKAGE_NAME: Wheel Build Success -------------------------"

WHEEL_FILE=$(find "$BUILD_HOME" -maxdepth 1 -name "jupyter_enterprise_gateway-*.whl" 2>/dev/null | head -1)
if [ -z "$WHEEL_FILE" ]; then
    echo "------------------$PACKAGE_NAME:Wheel_build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Wheel_Build_Fails"
    exit 1
fi

# Install the wheel in a clean venv
python3 -m venv --system-site-packages /tmp/jeg-test-env
source /tmp/jeg-test-env/bin/activate
if [ -n "$PYZMQ_WHEEL" ]; then
    pip install --force-reinstall --no-deps "$PYZMQ_WHEEL"
fi
if ! pip install --force-reinstall --no-deps "$WHEEL_FILE"; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    deactivate
    exit 1
fi

# Smoke test - run from /tmp so Python imports the installed wheel, not the source tree.
cd /tmp
if ! python3 -c "
from importlib.metadata import version
import enterprise_gateway
print('jupyter_enterprise_gateway', version('jupyter_enterprise_gateway'), '|', enterprise_gateway.__file__)
assert version('jupyter_enterprise_gateway') == '${PACKAGE_VERSION#v}'
"; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_test_Fails"
    cd "$BUILD_HOME"
    exit 2
fi
cd "$BUILD_HOME"
deactivate

# Remove dependency wheels so CI create_wheel_wrapper only finds the single target wheel
rm -f "$BUILD_HOME"/pyzmq-*.whl

echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
echo "$PACKAGE_URL $PACKAGE_NAME"
echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Both_Install_and_Test_Success"
exit 0
