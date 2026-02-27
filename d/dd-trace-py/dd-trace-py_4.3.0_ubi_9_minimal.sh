#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package           : dd-trace-py
# Version           : 4.3.0
# Source repo       : https://github.com/DataDog/dd-trace-py
# Tested on         : UBI:9 (ubi9/ubi-minimal)
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

PACKAGE_NAME=dd-trace-py
PACKAGE_URL=https://github.com/DataDog/dd-trace-py.git
PACKAGE_VERSION=${1:-v4.3.0}

# Use one interpreter everywhere (pip, setup.py, inline checks).
PYTHON_BIN=${PYTHON_BIN:-python3}

# Silence pip root warning
export PIP_ROOT_USER_ACTION=ignore

# libdatadog version to vendor crashtracker from
LIBDATADOG_VERSION=${LIBDATADOG_VERSION:-v25.0.0}

# Patches (default to upstream master)
DDTRACE_PATCH_URL="${DDTRACE_PATCH_URL:-${DDTRACE_PATCH:-https://raw.githubusercontent.com/ppc64le/build-scripts/master/d/dd-trace-py/patches/dd-trace-py_4.3.0.patch}}"
LIBDD_PATCH_URL="${LIBDD_PATCH_URL:-${LIBDATADOG_CRASHTRACKER_PATCH:-https://raw.githubusercontent.com/ppc64le/build-scripts/master/d/dd-trace-py/patches/libdatadog-crashtracker_25.0.0.patch}}"

# Optional: let callers pin a shared Cargo target dir (cache)
# export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-$(pwd)/.cargo-target}"

# Keep crashtracker runtime off for smoke test
export DD_USE_SYSTEM_LIBDATADOG=${DD_USE_SYSTEM_LIBDATADOG:-1}
export DD_NO_CRASHTRACKER=${DD_NO_CRASHTRACKER:-1}

# ----------------------------------------------------------------------------
# Install required dependencies
# ----------------------------------------------------------------------------
yum install -y wget git python3 python3-devel openssl openssl-devel make gcc gcc-c++ diffutils cmake patch rust cargo findutils libffi-devel elfutils-libelf-devel || true

if ! command -v patchelf >/dev/null 2>&1; then
  yum install -y autoconf automake libtool make gcc gcc-c++ m4 gettext || true
  cd /tmp && rm -rf patchelf && git clone https://github.com/NixOS/patchelf.git
  cd patchelf && ./bootstrap.sh && ./configure && make -j"$(nproc)" && make install
  command -v patchelf >/dev/null || { echo "[ERROR] patchelf installation failed"; exit 1; }
fi

# Upgrade pip & install Python build deps for THIS interpreter
# NOTE: ddtrace requires cmake >=3.24.2,<3.28 for source builds.
${PYTHON_BIN} -m ensurepip --upgrade || true
${PYTHON_BIN} -m pip install --upgrade pip
${PYTHON_BIN} -m pip install --upgrade 'setuptools<70' wheel
${PYTHON_BIN} -m pip install "cmake>=3.24.2,<3.28" cython "setuptools-rust<2" "setuptools_scm[toml]>=4" || true

# Guard: ensure pkg_resources is available to THIS interpreter (setup.py needs it)
${PYTHON_BIN} - <<'PY'
import sys
try:
    import pkg_resources; print("pkg_resources OK for", sys.executable)
except Exception:
    raise SystemExit(1)
PY
if [ $? -ne 0 ]; then
  ${PYTHON_BIN} -m pip install --upgrade 'setuptools<70'
fi

# ----------------------------------------------------------------------------
# Clone ddtrace and checkout version
# ----------------------------------------------------------------------------
git clone "${PACKAGE_URL}"
cd "${PACKAGE_NAME}"
git checkout "${PACKAGE_VERSION}"

# Apply ddtrace patch
echo "[INFO] Fetching ddtrace patch: ${DDTRACE_PATCH_URL}"
if ! wget -O ddtrace.patch "${DDTRACE_PATCH_URL}"; then
  echo "[ERROR] Failed to download ddtrace patch: ${DDTRACE_PATCH_URL}"
  exit 1
fi

if [ ! -s ddtrace.patch ]; then
  echo "[ERROR] ddtrace.patch is missing or empty"
  exit 1
fi

if ! git apply --ignore-whitespace ddtrace.patch; then
  echo "[ERROR] Failed to apply ddtrace patch"
  exit 1
fi

# ----------------------------------------------------------------------------
# Build libdatadog (crashtracker) and stage static archive into ddtrace
# ----------------------------------------------------------------------------
TMPDIR="$(mktemp -d)"
pushd "${TMPDIR}" >/dev/null
  git clone --depth=1 --branch "${LIBDATADOG_VERSION}" https://github.com/DataDog/libdatadog.git
  cd libdatadog

  # Apply libdatadog crashtracker patch
  echo "[INFO] Fetching libdatadog crashtracker patch: ${LIBDD_PATCH_URL}"
  if ! wget -O libdd.patch "${LIBDD_PATCH_URL}"; then
    echo "[ERROR] Failed to download libdatadog crashtracker patch from: ${LIBDD_PATCH_URL}"
    exit 1
  fi

  if [ ! -s libdd.patch ]; then
    echo "[ERROR] libdd.patch is missing or empty!"
    exit 1
  fi

  if ! git apply --ignore-whitespace libdd.patch; then
    echo "[ERROR] Failed to apply libdd.patch"
    exit 1
  fi

  # Pin libc crate version
  cargo update -p libc --precise 0.2.178

  # Build crashtracker staticlib
  cargo rustc --lib --release --crate-type staticlib -p libdd-crashtracker

  # Locate produced static archive (absolute paths; cover hashed & deps/)
  LOCAL_TARGET="$(pwd)/target"
  CRASH_A="$(find "${LOCAL_TARGET}" -type f -name 'liblibdd_crashtracker*.a' -print -quit 2>/dev/null || true)"
  if [ -z "${CRASH_A}" ] && [ -n "${CARGO_TARGET_DIR:-}" ]; then
    if ABS_CARGO_DIR="$(cd "${CARGO_TARGET_DIR}" 2>/dev/null && pwd)"; then
      ALT_A="$(find "${ABS_CARGO_DIR}" -type f -name 'liblibdd_crashtracker*.a' -print -quit 2>/dev/null || true)"
      [ -n "${ALT_A}" ] && CRASH_A="${ALT_A}"
    fi
  fi

  if [ -z "${CRASH_A}" ] || [ ! -f "${CRASH_A}" ]; then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails (crashtracker .a not found)"
    exit 1
  fi
  echo "[INFO] crashtracker archive: ${CRASH_A}"
popd >/dev/null

# Stage the crashtracker archive into ddtrace src/native/ (use absolute path)
mkdir -p src/native
cp -f "${CRASH_A}" src/native/liblibdd_crashtracker.a

# ----------------------------------------------------------------------------
# Build ddtrace native extension (Rust) and make it visible to CMake
# ----------------------------------------------------------------------------
pushd src/native >/dev/null
  cargo build --release --features "pyo3/extension-module profiling"

  # Discover produced .so (absolute search; support hashed names & alt target roots)
  HERE_TARGET="$(pwd)/target"
  SRC_SO="$(find "${HERE_TARGET}" ../target -type f \( -name 'libddtrace*_native*.so' -o -name 'lib_native*.so' \) -print -quit 2>/dev/null || true)"
  if [ -z "${SRC_SO}" ] && [ -n "${CARGO_TARGET_DIR:-}" ]; then
    if ABS_CARGO_DIR="$(cd "${CARGO_TARGET_DIR}" 2>/dev/null && pwd)"; then
      SRC_SO="$(find "${ABS_CARGO_DIR}" -type f \( -name 'libddtrace*_native*.so' -o -name 'lib_native*.so' \) -print -quit 2>/dev/null || true)"
    fi
  fi
popd >/dev/null

if [ -z "${SRC_SO}" ] || [ ! -f "${SRC_SO}" ]; then
  echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
  echo "$PACKAGE_VERSION $PACKAGE_NAME"
  echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails (native .so not found)"
  exit 1
fi

# Place .so where CMake's dd_wrapper expects it: build/lib.<plat>/.../_native.*.so
PLAT="$(${PYTHON_BIN} - <<'PY'
import sysconfig
print(sysconfig.get_platform())
PY
)"
SOABI="$(${PYTHON_BIN} - <<'PY'
import sysconfig, sys
print(sysconfig.get_config_var('SOABI') or f"cpython-{sys.version_info.major}{sys.version_info.minor}-{sys.platform}")
PY
)"
BUILD_LIB_DIR="build/lib.${PLAT}/ddtrace/internal/native"
mkdir -p "${BUILD_LIB_DIR}"
cp -f "${SRC_SO}" "${BUILD_LIB_DIR}/_native.${SOABI}.so"

# Also stage into the repo package tree so importing from source works
REPO_NATIVE_DIR="ddtrace/internal/native"
mkdir -p "${REPO_NATIVE_DIR}"
cp -f "${SRC_SO}" "${REPO_NATIVE_DIR}/_native.${SOABI}.so"

# ----------------------------------------------------------------------------
# Build Wheel (setup.py bdist_wheel, no build isolation)
# ----------------------------------------------------------------------------
# Guard again just before running setup.py (same interpreter):
${PYTHON_BIN} - <<'PY'
import sys
try:
    import pkg_resources; print("pkg_resources OK for", sys.executable)
except Exception as e:
    raise SystemExit(f"pkg_resources missing for {sys.executable}: {e}")
PY

if ! ${PYTHON_BIN} setup.py bdist_wheel --dist-dir="$(pwd)"; then
  echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
  echo "$PACKAGE_VERSION $PACKAGE_NAME"
  echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
  exit 1
fi

# Optional checksum
sha256sum ddtrace-*.whl > SHA256SUMS 2>/dev/null || true

# ----------------------------------------------------------------------------
# Install wheel (reuse if already correct) and run a minimal smoke test
# ----------------------------------------------------------------------------
echo "[INFO] Installing built wheel (always overwrite existing ddtrace)..."
${PYTHON_BIN} -m pip uninstall -y ddtrace || true
${PYTHON_BIN} -m pip cache purge || true
${PYTHON_BIN} -m pip install --no-cache-dir --force-reinstall ./ddtrace-*.whl

# Minimal runtime validation:
# - Run OUTSIDE the repo tree + empty PYTHONPATH so imports come from the installed wheel (site-packages)
CUR_DIR="$(pwd)"
cd /
PYTHONPATH="" ${PYTHON_BIN} - <<'PY'
import sys
from importlib.metadata import version
try:
    import ddtrace
    from ddtrace.internal.native import _native
except Exception as e:
    raise SystemExit(f"import failed: {e}")
print("imported-from:", ddtrace.__file__)
print("version:", version("ddtrace"))
print("_native OK:", _native is not None)
print("python:", sys.version)
PY
rc=$?
cd "${CUR_DIR}"

if [ ${rc} -ne 0 ]; then
  echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
  echo "$PACKAGE_VERSION $PACKAGE_NAME"
  echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Test_Fails"
  exit 2
fi

# Optional: tracer diagnostics (off by default; set SHOW_DDTRACE_INFO=1 to enable)
if [ "${SHOW_DDTRACE_INFO:-0}" = "1" ] && command -v ddtrace-run >/dev/null 2>&1; then
  # Helpful defaults to avoid tag warnings in the output
  export DD_SERVICE="${DD_SERVICE:-ddtrace-build}"
  export DD_ENV="${DD_ENV:-ci}"
  export DD_VERSION="${DD_VERSION:-${PACKAGE_VERSION#v}}"

  echo "[INFO] Running ddtrace-run --info (non-fatal)..."
  ddtrace-run --info || true
fi

echo "------------------$PACKAGE_NAME:install_and_test_success-------------------------"
echo "$PACKAGE_VERSION $PACKAGE_NAME"
echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Install_and_Test_Success"
exit 0