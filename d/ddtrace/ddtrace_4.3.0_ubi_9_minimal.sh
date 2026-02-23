#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package           : ddtrace
# Version           : 4.3.0
# Source repo       : https://github.com/DataDog/dd-trace-py
# Tested on         : UBI:9.3
# Language          : Python,Rust
# Ci-Check          : True
# Script License    : Apache License, Version 2 or later
# Maintainer        : Vikash Kumar Singh <Vikash.Singh14@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=ddtrace
PACKAGE_URL=https://github.com/DataDog/dd-trace-py.git
PACKAGE_VERSION=${1:-v4.3.0}

# libdatadog version to vendor crashtracker from
LIBDATADOG_VERSION=${LIBDATADOG_VERSION:-v25.0.0}

# Patches hosted in build-scripts (Agent-style: fetch via wget then git apply)
DDTRACE_PATCH_URL=${DDTRACE_PATCH_URL:-https://raw.githubusercontent.com/ppc64le/build-scripts/master/d/ddtrace/patches/ddtrace_4.3.0.patch}
LIBDD_PATCH_URL=${LIBDD_PATCH_URL:-https://raw.githubusercontent.com/ppc64le/build-scripts/master/d/ddtrace/patches/libdatadog-crashtracker_25.0.0.patch}

# Build toggles (keep crashtracker off at runtime for smoke test)
export DD_USE_SYSTEM_LIBDATADOG=${DD_USE_SYSTEM_LIBDATADOG:-1}
export DD_NO_CRASHTRACKER=${DD_NO_CRASHTRACKER:-1}

# ----------------------------------------------------------------------------
# Install required dependencies
# ----------------------------------------------------------------------------
yum install -y wget git python3 python3-devel openssl openssl-devel make gcc gcc-c++ diffutils cmake patch rust cargo findutils libffi-devel elfutils-libelf-devel

# Ensure pip/setuptools/wheel and build deps required by ddtrace build system
# NOTE: ddtrace build docs require cmake >=3.24.2,<3.28 for source builds.
python3 -m pip install --upgrade pip setuptools wheel
python3 -m pip install "cmake>=3.24.2,<3.28" cython "setuptools-rust<2" "setuptools_scm[toml]>=4" pytest twine || true

# ----------------------------------------------------------------------------
# Clone ddtrace and checkout version
# ----------------------------------------------------------------------------
git clone "${PACKAGE_URL}"
cd "${PACKAGE_NAME}"
git checkout "${PACKAGE_VERSION}"

# Apply ddtrace patch (if available)
wget -O ddtrace.patch "${DDTRACE_PATCH_URL}" || true
if [ -s ddtrace.patch ]; then
  git apply --ignore-whitespace ddtrace.patch || true
fi

# ----------------------------------------------------------------------------
# Build libdatadog (crashtracker) and stage static archive into ddtrace
# ----------------------------------------------------------------------------
TMPDIR="$(mktemp -d)"
pushd "${TMPDIR}" >/dev/null
  git clone --depth=1 --branch "${LIBDATADOG_VERSION}" https://github.com/DataDog/libdatadog.git
  cd libdatadog

  # Apply libdatadog crashtracker patch (if available)
  wget -O libdd.patch "${LIBDD_PATCH_URL}" || true
  if [ -s libdd.patch ]; then
    git apply --ignore-whitespace libdd.patch || true
  fi

  # Pin libc crate as per working flow
  cargo update -p libc --precise 0.2.178

  # Build crashtracker staticlib
  cargo rustc --lib --release --crate-type staticlib -p libdd-crashtracker

  # Locate produced static archive (hashed or plain)
  CRASH_A="$(find target -type f -name 'liblibdd_crashtracker*.a' | head -n1 || true)"
  if [ -z "${CRASH_A}" ] || [ ! -f "${CRASH_A}" ]; then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails (crashtracker .a not found)"
    exit 1
  fi
popd >/dev/null

# Stage the crashtracker archive into ddtrace src/native/
mkdir -p src/native
cp -f "${TMPDIR}/${CRASH_A}" src/native/liblibdd_crashtracker.a

# ----------------------------------------------------------------------------
# Build ddtrace native extension (Rust) and make it visible to CMake
# ----------------------------------------------------------------------------
pushd src/native >/dev/null
  cargo build --release --features "pyo3/extension-module profiling"

  # Discover produced .so (support hashed filenames in target tree)
  SRC_SO="$(find target ../target -type f \( -name 'libddtrace*_native*.so' -o -name 'lib_native*.so' \) 2>/dev/null | head -n1 || true)"
  if [ -z "${SRC_SO}" ] || [ ! -f "${SRC_SO}" ]; then
    SRC_SO="$(find "${CARGO_TARGET_DIR:-.}" -type f \( -name 'libddtrace*_native*.so' -o -name 'lib_native*.so' \) 2>/dev/null | head -n1 || true)"
  fi
popd >/dev/null

if [ -z "${SRC_SO}" ] || [ ! -f "${SRC_SO}" ]; then
  echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
  echo "$PACKAGE_VERSION $PACKAGE_NAME"
  echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails (native .so not found)"
  exit 1
fi

# Place .so where CMake's dd_wrapper expects it: build/lib.<plat>/.../_native.*.so
PLAT="$(python3 - <<'PY'
from pkg_resources import get_build_platform
print(get_build_platform())
PY
)"
SOABI="$(python3 - <<'PY'
import sysconfig, sys
print(sysconfig.get_config_var('SOABI') or f"cpython-{sys.version_info.major}{sys.version_info.minor}-{sys.platform}")
PY
)"
BUILD_LIB_DIR="build/lib.${PLAT}/ddtrace/internal/native"
mkdir -p "${BUILD_LIB_DIR}"
cp -f "${SRC_SO}" "${BUILD_LIB_DIR}/_native.${SOABI}.so"

# ----------------------------------------------------------------------------
# Build Wheel (Agent-style: setup.py bdist_wheel, no build isolation)
# ----------------------------------------------------------------------------
if ! python3 setup.py bdist_wheel --dist-dir="$(pwd)"; then
  echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
  echo "$PACKAGE_VERSION $PACKAGE_NAME"
  echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
  exit 1
fi

# Optional checksum (not required but helpful)
sha256sum ddtrace-*.whl > SHA256SUMS 2>/dev/null || true

# ----------------------------------------------------------------------------
# Install wheel and run upstream smoke test (tests/smoke_test.py) via pytest
# ----------------------------------------------------------------------------
python3 -m pip install --force-reinstall ./ddtrace-*.whl

# Run only the upstream smoke test to validate install/runtime
if ! python3 -m pytest -q tests/smoke_test.py; then
  echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
  echo "$PACKAGE_VERSION $PACKAGE_NAME"
  echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Test_Fails"
  exit 2
fi

echo "------------------$PACKAGE_NAME:install_and_test_success-------------------------"
echo "$PACKAGE_VERSION $PACKAGE_NAME"
echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Install_and_Test_Success"
exit 0