#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package           : ddtrace
# Version           : 4.3.0
# Source repo       : https://github.com/DataDog/dd-trace-py
# Tested on         : UBI:9
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

# In agent-style scripts, PACKAGE_NAME equals the directory created by git clone.
PACKAGE_NAME=dd-trace-py
PACKAGE_URL=https://github.com/DataDog/dd-trace-py.git
PACKAGE_VERSION=${1:-v4.3.0}

# Use one interpreter everywhere (pip, setup.py, inline checks).
PYTHON_BIN=${PYTHON_BIN:-python3}

# libdatadog version to vendor crashtracker from
LIBDATADOG_VERSION=${LIBDATADOG_VERSION:-v25.0.0}

# Patches (default to upstream master; override via env for local testing)
DDTRACE_PATCH_URL=${DDTRACE_PATCH_URL:-https://raw.githubusercontent.com/vikashsingh14/build-scripts/feat/ddtrace-4.3.0/d/ddtrace/patches/ddtrace_4.3.0.patch}
LIBDD_PATCH_URL=${LIBDD_PATCH_URL:-https://raw.githubusercontent.com/vikashsingh14/build-scripts/feat/ddtrace-4.3.0/d/ddtrace/patches/libdatadog-crashtracker_25.0.0.patch}

# Optional: let callers pin a shared Cargo target dir (cache)
# export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-$(pwd)/.cargo-target}"

# Keep crashtracker runtime off for smoke test/containers
export DD_USE_SYSTEM_LIBDATADOG=${DD_USE_SYSTEM_LIBDATADOG:-1}
export DD_NO_CRASHTRACKER=${DD_NO_CRASHTRACKER:-1}

# ----------------------------------------------------------------------------
# Install required dependencies
# ----------------------------------------------------------------------------
yum install -y wget git python3 python3-devel openssl openssl-devel make gcc gcc-c++ diffutils cmake patch rust cargo findutils libffi-devel elfutils-libelf-devel || true

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
# Build Wheel (Agent-style: setup.py bdist_wheel, no build isolation)
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

# Expected version for the installed package (strip leading 'v': v4.3.0 -> 4.3.0)
export WANT_DDTRACE_VERSION="${PACKAGE_VERSION#v}"

# Check if ddtrace is already installed with the required version
${PYTHON_BIN} - <<'PY'
import os, sys
from importlib.metadata import version, PackageNotFoundError
want = os.environ.get("WANT_DDTRACE_VERSION", "").strip()
try:
    cur = version("ddtrace")
    print(f"[INFO] ddtrace already installed: {cur}")
    # Exit 0 only if exact version matches; 101 = mismatch, 100 = not installed
    sys.exit(0 if (want and cur == want) else 101)
except PackageNotFoundError:
    sys.exit(100)
PY

rc=$?
if [ $rc -eq 100 ] || [ $rc -eq 101 ]; then
  echo "[INFO] Installing local wheel (force-reinstall) ..."
  ${PYTHON_BIN} -m pip install --force-reinstall ./ddtrace-*.whl
else
  echo "[INFO] Reusing existing ddtrace installation (version ${WANT_DDTRACE_VERSION})."
fi

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
print("imported-from:", ddtrace.__file__)        # should be a site-packages path, not the repo
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

# Keep DD_TRACE_ENABLED as-is; print tracer info (non-fatal if Agent not running)
if command -v ddtrace-run >/dev/null 2>&1; then
  ddtrace-run --info || true
fi

echo "------------------$PACKAGE_NAME:install_and_test_success-------------------------"
echo "$PACKAGE_VERSION $PACKAGE_NAME"
echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Install_and_Test_Success"
exit 0