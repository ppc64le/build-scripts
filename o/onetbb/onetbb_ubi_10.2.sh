
#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : tbb
# Version          : 2023.1.0
# Source repo      : https://github.com/uxlfoundation/oneTBB
# Tested on        : UBI:10.2
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Sakshi Jain <sakshi.jain16@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

set -ex

PACKAGE_NAME=tbb
PACKAGE_VERSION=${1:-2023.1.0}
PACKAGE_URL=https://github.com/uxlfoundation/oneTBB
PACKAGE_DIR=oneTBB
ONETBB_INSTALL=/tmp/my_installed_onetbb
CURRENT_DIR=$(pwd)
WHEEL_DIR=/tmp/tbb_wheels
mkdir -p "$WHEEL_DIR"

# ---------------------------------------------------------------------------
# System dependencies
# Python packages listed first (required by create_wheel_wrapper.sh ordering)
# ---------------------------------------------------------------------------
dnf install -y python3.14 python3.14-devel python3.14-pip \
    git gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ \
    make cmake wget \
    openssl-devel bzip2-devel pcre2-devel \
    libffi-devel zlib-devel pkg-config

# ---------------------------------------------------------------------------
# Activate GCC Toolset 15 (UBI 10 dropped SCL — no source enable script)
# ---------------------------------------------------------------------------
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

export GCC_HOME=/opt/rh/gcc-toolset-15/root/usr
export CC=$GCC_HOME/bin/gcc
export CXX=$GCC_HOME/bin/g++

# ---------------------------------------------------------------------------
# Python build tools (always via pip, never via dnf)
# ---------------------------------------------------------------------------
python3.14 -m pip install --upgrade pip setuptools wheel build

# ---------------------------------------------------------------------------
# Install SWIG from the official release tarball (SourceForge).
# The release tarball ships pre-generated CParse/parser.c — no bison needed.
# No RPM available in UBI 10.2.
# ---------------------------------------------------------------------------
if ! command -v swig &>/dev/null; then
    echo " ------------------------------ Installing SWIG ------------------------------ "
    SWIG_VERSION="4.2.1"
    if [[ ! -d "swig-${SWIG_VERSION}" ]]; then
        curl -fSL --retry 3 --retry-delay 5 \
            "https://sourceforge.net/projects/swig/files/swig/swig-${SWIG_VERSION}/swig-${SWIG_VERSION}.tar.gz/download" \
            -o "swig-${SWIG_VERSION}.tar.gz"
        tar -xzf "swig-${SWIG_VERSION}.tar.gz"
    fi
    cd "swig-${SWIG_VERSION}"
    ./configure --prefix=/usr/local --without-alllang --with-python3
    # Build only the swig binary — skip tests and examples
    make -j"$(nproc)" swig
    install -m 755 swig /usr/local/bin/swig
    # Install SWIG's Lib/ runtime interface files
    mkdir -p /usr/local/share/swig/${SWIG_VERSION}
    cp -r Lib/* /usr/local/share/swig/${SWIG_VERSION}/
    cd "$CURRENT_DIR"
    echo " ------------------------------ SWIG Installed Successfully ------------------------------ "
fi
swig -version

# ---------------------------------------------------------------------------
# Clone & checkout oneTBB
# ---------------------------------------------------------------------------
echo "------------Cloning the Repository------------"
if [[ ! -d "$PACKAGE_DIR" ]]; then
    git clone "$PACKAGE_URL" "$PACKAGE_DIR"
fi
cd "$PACKAGE_DIR"

if git rev-parse "v${PACKAGE_VERSION}" &>/dev/null; then
    git checkout "v${PACKAGE_VERSION}"
elif git rev-parse "${PACKAGE_VERSION}" &>/dev/null; then
    git checkout "${PACKAGE_VERSION}"
else
    echo "ERROR: No git tag found for version '${PACKAGE_VERSION}'"
    exit 1
fi

# Reset any modified files from a previous run so patches apply cleanly
git checkout -- .

# ---------------------------------------------------------------------------
# Patch python/setup.py — add lib64 to library_dirs and fix version string
# ---------------------------------------------------------------------------
echo "------------Applying Patch------------"
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/o/onetbb/tbb_ubi_10.2.patch
git apply tbb_ubi_10.2.patch
echo "------------Applied patch successfully---------------------"

# ---------------------------------------------------------------------------
# CMake build — compile oneTBB and Python bindings
# CXXFLAGS/LDFLAGS must NOT be set here: CMake's compiler test links a
# probe binary and would fail trying to resolve -ltbb before it is built.
# ---------------------------------------------------------------------------

# Clear any flags that reference libtbb before CMake's compiler probe runs
unset CXXFLAGS LDFLAGS

# Remove stale CMake cache — a previous run may have baked in -ltbb flags
rm -rf build
mkdir -p build
cd build

if ! cmake \
    -DCMAKE_INSTALL_PREFIX="$ONETBB_INSTALL" \
    -DSWIG_EXECUTABLE="$(which swig)" \
    -DTBB_TEST=OFF \
    -DBUILD_SHARED_LIBS=ON \
    -DTBB_BUILD=ON \
    -DTBB4PY_BUILD=ON \
    -DTBB_DISABLE_HWLOC_AUTOMATIC_SEARCH=ON \
    -DTBBBIND_2_5_LIBRARY_DIR="" \
    ..; then
    echo "------------------$PACKAGE_NAME:cmake_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  CMAKE_Fails"
    exit 1
fi

echo "------------Building the package------------"
if ! make -j"$(nproc)" python_build; then
    echo "------------------$PACKAGE_NAME:make_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  MAKE_Fails"
    exit 1
fi

export LD_LIBRARY_PATH="$ONETBB_INSTALL/lib64:$LD_LIBRARY_PATH"

echo "------------Installing the package------------"
if ! make install; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# ---------------------------------------------------------------------------
# Build wheel from python/ — setup.py already patched to include lib64 path
# ---------------------------------------------------------------------------
echo "=============== Building wheel =================="
export TBBROOT="$ONETBB_INSTALL"
export LD_LIBRARY_PATH="$ONETBB_INSTALL/lib64:${LD_LIBRARY_PATH:-}"
# LDFLAGS injects -L directly into the linker — bypasses setup.py library_dirs
export LDFLAGS="-L$ONETBB_INSTALL/lib64"

cd "$CURRENT_DIR/$PACKAGE_DIR/python"
# Clean all build artifacts so setup.py rebuilds from scratch
rm -rf build dist *.egg-info

if ! python3.14 setup.py bdist_wheel --dist-dir="$WHEEL_DIR/"; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi
cp "$WHEEL_DIR"/tbb*.whl "$CURRENT_DIR/" 2>/dev/null || true

# ---------------------------------------------------------------------------
# Smoke test — run from /tmp so Python cannot shadow the installed wheel
# with the source tree's tbb/ directory
# ---------------------------------------------------------------------------
python3.14 -m pip install "$WHEEL_DIR"/tbb*.whl --force-reinstall

cd /tmp
if ! python3.14 -c "import tbb; print('tbb import OK')"; then
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
