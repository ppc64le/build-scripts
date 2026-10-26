#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : numba
# Version       : 0.65.1
# Source repo   : https://github.com/numba/numba
# Tested on     : UBI 10.2
# Language      : Python
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Amit Kumar <amit.kumar282@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=numba
PACKAGE_VERSION=${1:-"0.65.1"}
PACKAGE_URL=https://github.com/numba/numba
PACKAGE_DIR=numba
WORKING_DIR=$(pwd)
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

LLVMLITE_VERSION="0.47.0"
NUMPY_VERSION="2.4.6"
DEVFIRST_INDEX="https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/"

# -----------------------------------------------------------------------------
# CPU optimization flags
# -----------------------------------------------------------------------------
if grep -q "POWER10" /proc/cpuinfo 2>/dev/null; then
    CPU_FLAGS="-mcpu=power10 -mtune=power10"
    echo "Detected POWER10 - applying power10 optimization flags"
else
    CPU_FLAGS=""
    echo "POWER10 not detected - no arch-specific flags applied"
fi

export CFLAGS="${CPU_FLAGS}"
export CXXFLAGS="${CPU_FLAGS}"

# -----------------------------------------------------------------------------
# System dependencies
# -----------------------------------------------------------------------------
yum install -y wget git gcc gcc-c++ \
    python3-pip python3-devel \
    libffi-devel openssl-devel bzip2-devel xz-devel zlib-devel

gcc --version
g++ --version

python3 --version
python3 -m pip install --upgrade pip
python3 -m pip install setuptools wheel build auditwheel patchelf

# -----------------------------------------------------------------------------
# Install numpy and llvmlite
# -----------------------------------------------------------------------------
echo "-------------------Installing numpy and llvmlite from DevFirst portal----------------------"
if ! python3 -m pip install \
        --index-url "${DEVFIRST_INDEX}" \
        "numpy==${NUMPY_VERSION}" \
        "llvmlite==${LLVMLITE_VERSION}"; then
    echo "------------------numpy/llvmlite:install_fails---------------------------------------"
    echo "$PACKAGE_NAME | ${DEVFIRST_INDEX} | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi
echo "-------------------numpy and llvmlite installed successfully----------------------"

# -----------------------------------------------------------------------------
# Clone numba
# -----------------------------------------------------------------------------
echo "-------------------Building numba ${PACKAGE_VERSION} wheel----------------------"

rm -rf "$PACKAGE_DIR"
if ! git clone --depth 1 --branch "$PACKAGE_VERSION" "$PACKAGE_URL" "$PACKAGE_DIR"; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Clone_Fails"
    exit 1
fi

cd "$PACKAGE_DIR"

# -----------------------------------------------------------------------------
# Build numba wheel
# -----------------------------------------------------------------------------
if ! python3 -m build --wheel --no-isolation; then
    echo "------------------$PACKAGE_NAME:build_fails---------------------------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Build_Fails"
    exit 1
fi
cd "$WORKING_DIR"
echo "-------------------numba wheel built successfully----------------------"

# -----------------------------------------------------------------------------
# Repair numba wheel with auditwheel - bundles all non-system shared libraries
# (.so files) into the wheel and retags it as manylinux.
# -----------------------------------------------------------------------------
echo "-------------------Repairing numba wheel with auditwheel----------------------"

WHEEL_DIR="$WORKING_DIR/$PACKAGE_DIR/dist"
REPAIRED_DIR="$WORKING_DIR/repaired_dist"
mkdir -p "$REPAIRED_DIR"

if ! python3 -m auditwheel repair \
        --wheel-dir "$REPAIRED_DIR" \
        "$WHEEL_DIR"/*.whl; then
    echo "------------------$PACKAGE_NAME:auditwheel_fails---------------------------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Auditwheel_Fails"
    exit 1
fi
echo "-------------------auditwheel repair completed----------------------"
echo "Repaired wheel:"
ls -lh "$REPAIRED_DIR"/*.whl

# -----------------------------------------------------------------------------
# Install repaired numba wheel
# -----------------------------------------------------------------------------
if ! python3 -m pip install "$REPAIRED_DIR"/*.whl; then
    echo "------------------$PACKAGE_NAME:install_fails---------------------------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi

# -----------------------------------------------------------------------------
# Smoke test - verify installed versions and target triple.
# -----------------------------------------------------------------------------
if ! python3 <<EOF
import sys, numpy as np, numba, llvmlite, llvmlite.binding as llvm

print("Python   :", sys.version.split()[0])
print("NumPy    :", np.__version__)
print("llvmlite :", llvmlite.__version__)
print("LLVM     :", ".".join(map(str, llvm.llvm_version_info)))
print("Numba    :", numba.__version__)

assert numba.__version__ == "${PACKAGE_VERSION}", numba.__version__
assert llvmlite.__version__ == "${LLVMLITE_VERSION}", llvmlite.__version__

assert llvm.llvm_version_info[0] == 20, llvm.llvm_version_info

triple = llvm.get_default_triple()
print("Triple   :", triple)
assert "powerpc64le" in triple, f"Unexpected triple: {triple}"
print("PowerPC64LE target: OK")
EOF
then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 2
fi

# -----------------------------------------------------------------------------
# Import test - verify the installed numba sub-packages import cleanly.
# Run from /tmp so Python imports the installed numba, not the source tree.
# -----------------------------------------------------------------------------
cd /tmp
if ! python3 -c "import numba; import numba.core.annotations; import numba.core.datamodel; import numba.core.rewrites; import numba.core.runtime; import numba.core.typing; import numba.core.unsafe; import numba.experimental.jitclass; import numba.np.ufunc; import numba.pycc; import numba.scripts; import numba.testing; import numba.tests; import numba.tests.npyufunc;"; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    cd "$WORKING_DIR"
    exit 2
fi
cd "$WORKING_DIR"

echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
echo "Wheel: $(ls "$REPAIRED_DIR"/*.whl)"
exit 0
