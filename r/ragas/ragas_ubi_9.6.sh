#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : ragas
# Version          : v0.4.3
# Source repo      : https://github.com/vibrantlabsai/ragas.git
# Tested on        : UBI:9.6
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Bhagyashri Gaikwad <Bhagyashri.Gaikwad2@ibm.com> 
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash
set -ex
PACKAGE_NAME=ragas
PACKAGE_VERSION=${1:-v0.4.3}
PACKAGE_URL=https://github.com/vibrantlabsai/ragas
PACKAGE_DIR=ragas
CURRENT_DIR="${PWD}"

# IBM ppc64le wheels
IBM_WHEELS="https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/"

# Package versions
NUMPY_VERSION="2.2.6"
SCIPY_VERSION="1.17.0"
PILLOW_VERSION="12.1.1+ppc64le1"
PYARROW_VERSION="22.0.0"
SCIKIT_NETWORK_VERSION="v0.33.5"

# scikit-network source
SCIKIT_NETWORK_URL="https://github.com/sknetwork-team/scikit-network.git"
SCIKIT_NETWORK_DIR="scikit-network"

# ============================================================
# Install system dependencies
# ============================================================

yum install -y git gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc-gfortran make wget openssl-devel bzip2-devel glibc-static libstdc++-static libffi-devel zlib-devel libxml2-devel libxslt-devel python3.12 python3.12-devel python3.12-pip pkg-config cmake openblas-devel rust cargo

source /opt/rh/gcc-toolset-13/enable

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH

export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:/opt/rh/gcc-toolset-13/root/usr/lib:$LD_LIBRARY_PATH

export LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:/usr/lib64:/usr/local/lib64:$LIBRARY_PATH

export PKG_CONFIG_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64/pkgconfig:/usr/lib64/pkgconfig:/usr/local/lib64/pkgconfig:$PKG_CONFIG_PATH

# ============================================================
# Clone Ragas
# ============================================================

git clone "${PACKAGE_URL}"

cd "${PACKAGE_NAME}"

git checkout "${PACKAGE_VERSION}"

# Verify checked-out version
git describe --tags --always

# ============================================================
# Upgrade pip/setuptools/wheel
# ============================================================

python3.12 -m pip install --upgrade \
    pip \
    setuptools \
    wheel

# ============================================================
# Install Python build/test dependencies
# ============================================================

python3.12 -m pip install \
    packaging \
    pytest \
    pytest-asyncio \
    pytest-xdist \
    build \
    cython \
    setuptools-rust \
    maturin \
    hatch \
    hatch-vcs \
    "langchain-community==0.3.31"


python3.12 -m pip install \
    --trusted-host wheels.developerfirst.ibm.com \
    --extra-index-url "${IBM_WHEELS}" \
    --only-binary=numpy,scipy,Pillow,pyarrow,pandas \
    "numpy==${NUMPY_VERSION}" \
    "scipy==${SCIPY_VERSION}" \
    "Pillow==${PILLOW_VERSION}" \
    "pyarrow==${PYARROW_VERSION}" \
    pandas \
    tiktoken==0.12.0+ppc64le1 \
    orjson \
    ormsgpack

# ============================================================
# Build scikit-network v0.33.5 from source
# ============================================================

cd "${CURRENT_DIR}"

git clone "${SCIKIT_NETWORK_URL}" "${SCIKIT_NETWORK_DIR}"

cd "${SCIKIT_NETWORK_DIR}"

git checkout "${SCIKIT_NETWORK_VERSION}"

# Verify source version
git describe --tags --always


python3.12 -m pip install --no-build-isolation .

cd "${CURRENT_DIR}"

# ============================================================
# Verify scikit-network
# ============================================================

python3.12 -c "import sknetwork; print('scikit-network:', sknetwork.__version__)"

# ============================================================
# Ragas: Generate version file
# ============================================================

cd "${CURRENT_DIR}/${PACKAGE_DIR}"

python3.12 -m hatch build --hooks-only

# Verify generated version file
test -f src/ragas/_version.py

cat src/ragas/_version.py

# ============================================================
# Install Ragas
# ============================================================

if ! python3.12 -m pip install --no-build-isolation -e . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
fi

# ============================================================
# Verify Ragas
# ============================================================

python3.12 -c "import ragas; print('Ragas:', ragas.__version__)"

# ============================================================
# Run Ragas tests
# ============================================================
if python3.12 -m pytest -v --capture=no -p no:warnings -n 2 tests/unit; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_VERSION | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL"
    echo "$PACKAGE_NAME | $PACKAGE_VERSION | GitHub | Pass | Install_and_Test_Success"
fi
