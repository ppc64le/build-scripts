#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pyarrow
# Version       : apache-arrow-24.0.0
# Source repo   : https://github.com/apache/arrow
# Tested on     : UBI:10.2
# Language      : Python, C++
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Amit Kumar <amit.kumar282@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=pyarrow
PACKAGE_VERSION=${1:-apache-arrow-24.0.0}
PACKAGE_URL=https://github.com/apache/arrow
PACKAGE_DIR=arrow
WORKDIR="$(pwd -P)"
WORKDIR="${WORKDIR%/}"

# ---------------------------------------------------------------------------
# System dependencies
# ---------------------------------------------------------------------------
echo "Install dependencies and tools."
dnf install -y --allowerasing gcc gcc-c++ make cmake ninja-build git binutils openssl openssl-devel zlib-devel libuuid-devel libcurl-devel libatomic cargo python3 python3-pip python3-devel

# ---------------------------------------------------------------------------
# Rust toolchain
# ---------------------------------------------------------------------------
if ! (curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
        | sh -s -- --default-toolchain stable -y); then
    echo "------------------${PACKAGE_NAME}:rust_install_fails--------------------------------"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | Fail | Rust_Install_Fails"
    exit 1
fi
source "$HOME/.cargo/env"
rustc --version

# ---------------------------------------------------------------------------
# CPU optimization flags
# ---------------------------------------------------------------------------
if grep -q "POWER10" /proc/cpuinfo 2>/dev/null; then
    CPU_FLAGS="-mcpu=power10 -mtune=power10"
    echo "Detected POWER10 - applying power10 optimization flags"
else
    CPU_FLAGS=""
    echo "POWER10 not detected - no arch-specific flags applied"
fi

export CFLAGS="${CPU_FLAGS}"
export CXXFLAGS="${CPU_FLAGS}"

# ---------------------------------------------------------------------------
# Clone
# ---------------------------------------------------------------------------
cd "${WORKDIR:-/}"
rm -rf "${PACKAGE_DIR}"

echo "Entering Pyarrow source directory..."
if ! git clone "${PACKAGE_URL}" "${PACKAGE_DIR}"; then
    echo "------------------${PACKAGE_NAME}:clone_fails---------------------------------------"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | Fail | Clone_Fails"
    exit 1
fi

cd "${PACKAGE_DIR}"
git checkout "${PACKAGE_VERSION}"
git submodule update --init --recursive

# ---------------------------------------------------------------------------
# Build Arrow C++
# ---------------------------------------------------------------------------
cd cpp
mkdir -p release && cd release
if ! cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DCMAKE_C_FLAGS="${CFLAGS}" \
      -DCMAKE_CXX_FLAGS="${CXXFLAGS}" \
      -DARROW_PYTHON=ON \
      -DARROW_COMPUTE=ON \
      -DARROW_PARQUET=ON \
      -DPARQUET_REQUIRE_ENCRYPTION=ON \
      -DARROW_ORC=ON \
      -DARROW_FILESYSTEM=ON \
      -DARROW_FLIGHT=ON \
      -DARROW_WITH_LZ4=ON \
      -DARROW_WITH_ZSTD=ON \
      -DARROW_WITH_SNAPPY=ON \
      -DARROW_WITH_ZLIB=ON \
      -DARROW_WITH_BROTLI=ON \
      -DARROW_WITH_BZ2=ON \
      -DARROW_WITH_UTF8PROC=ON \
      -DARROW_JSON=ON \
      -DARROW_CSV=ON \
      -DARROW_DATASET=ON \
      -DARROW_S3=ON \
      -DARROW_BUILD_TESTS=OFF \
      -DARROW_SUBSTRAIT=ON \
      -DARROW_JEMALLOC=OFF \
      -DARROW_MIMALLOC=OFF \
      -DProtobuf_SOURCE=BUNDLED \
      -DARROW_DEPENDENCY_SOURCE=BUNDLED \
    ..; then
    echo "------------------${PACKAGE_NAME}:arrow_cpp_configure_fails-------------------------"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | Fail | Arrow_Cpp_Configure_Fails"
    exit 1
fi

if ! make -j$(nproc); then
    echo "------------------${PACKAGE_NAME}:arrow_cpp_build_fails-----------------------------"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | Fail | Arrow_Cpp_Build_Fails"
    exit 1
fi

if ! make install; then
    echo "------------------${PACKAGE_NAME}:arrow_cpp_install_fails---------------------------"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | Fail | Arrow_Cpp_Install_Fails"
    exit 1
fi

echo "/usr/local/lib64" > /etc/ld.so.conf.d/arrow.conf 2>/dev/null || true
ldconfig 2>/dev/null || true

cd ../../python
export LD_LIBRARY_PATH=/usr/local/lib64:$LD_LIBRARY_PATH

# ---------------------------------------------------------------------------
# Build wheel
# ---------------------------------------------------------------------------
DEVFIRST_INDEX="https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/"
NUMPY_VERSION="2.4.6"

python3 -m pip install --upgrade pip

echo "Installing pre-built numpy from DevFirst..."
if ! python3 -m pip install \
        --index-url "${DEVFIRST_INDEX}" \
        "numpy==${NUMPY_VERSION}"; then
    echo "------------------${PACKAGE_NAME}:numpy_install_fails-------------------------------"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | Fail | Numpy_Install_Fails"
    exit 1
fi

if ! python3 -m pip install --extra-index-url "${DEVFIRST_INDEX}" --prefer-binary -r requirements-wheel-build.txt auditwheel patchelf build ninja; then
    echo "------------------${PACKAGE_NAME}:build_requirements_install_fails------------------"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | Fail | Build_Requirements_Install_Fails"
    exit 1
fi

echo "Building pyarrow wheel..."
mkdir -p "${WORKDIR}/dist"
if ! SETUPTOOLS_SCM_PRETEND_VERSION=${PACKAGE_VERSION#apache-arrow-} \
     CMAKE_PREFIX_PATH=/usr/local \
     python3 -m build --wheel --no-isolation --outdir "${WORKDIR}/dist"; then
    echo "------------------${PACKAGE_NAME}:wheel_build_fails---------------------------------"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | Fail | Wheel_Build_Fails"
    exit 1
fi

WHEEL=$(find "${WORKDIR}/dist" -maxdepth 1 -type f -name "pyarrow-*.whl" | head -1)
if [ -z "${WHEEL}" ]; then
    echo "------------------${PACKAGE_NAME}:wheel_not_found-----------------------------------"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | Fail | Wheel_Not_Found"
    exit 1
fi
echo "Wheel: ${WHEEL}"
cd "${WORKDIR:-/}"

# ---------------------------------------------------------------------------
# Install wheel in an isolated venv
# ---------------------------------------------------------------------------
rm -rf "${WORKDIR}/venv-test"
if ! python3 -m venv "${WORKDIR}/venv-test"; then
    echo "------------------${PACKAGE_NAME}:venv_create_fails---------------------------------"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | Fail | Venv_Create_Fails"
    exit 1
fi
VENV_PY="${WORKDIR}/venv-test/bin/python"
${VENV_PY} -m pip install --upgrade pip

if ! ${VENV_PY} -m pip install "${WHEEL}"; then
    echo "------------------${PACKAGE_NAME}:install_fails-------------------------------------"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | Fail | Install_Fails"
    exit 1
fi

# ---------------------------------------------------------------------------
# Test
# ---------------------------------------------------------------------------
if ! ${VENV_PY} -m pip install --index-url "${DEVFIRST_INDEX}" "numpy==${NUMPY_VERSION}"; then
    echo "------------------${PACKAGE_NAME}:install_success_but_test_fails---------------------"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | Fail | Test_Dependencies_Install_Fails"
    exit 2
fi

if ! ${VENV_PY} -m pip install --extra-index-url "${DEVFIRST_INDEX}" --prefer-binary pytest pytest-timeout hypothesis cffi pytz; then
    echo "------------------${PACKAGE_NAME}:install_success_but_test_fails---------------------"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | Fail | Test_Dependencies_Install_Fails"
    exit 2
fi
echo "Validating pyarrow installation..."
if ! ${VENV_PY} -c "import pyarrow as pa; print('pyarrow version:', pa.__version__)"; then
    echo "------------------${PACKAGE_NAME}:install_success_but_test_fails---------------------"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | Fail | Validation_Fails"
    exit 2
fi

# ---------------------------------------------------------------------------
# Test
# Test cases skipped and reasons:
#   - test_s3_finalize / test_s3_finalize_region_resolver / test_concurrent_s3fs_init:
#       AWS C++ SDK subprocess teardown triggers glibc static destructor abort on exit in UBI 10.2 (glibc 2.39).
#   - test_env_var_io_thread_count:
#       Spawns standalone python child process triggering same glibc exit teardown abort.
# ---------------------------------------------------------------------------
echo "Running upstream pyarrow tests..."
cd "${WORKDIR:-/}"
if ! ARROW_TEST_DATA="${WORKDIR}/${PACKAGE_DIR}/testing/data" \
     PARQUET_TEST_DATA="${WORKDIR}/${PACKAGE_DIR}/cpp/submodules/parquet-testing/data" \
     ${VENV_PY} -c "import os, pytest; os._exit(pytest.main(['--pyargs', 'pyarrow', '-v', '--tb=short', '-k', 'not test_s3_finalize and not test_s3_finalize_region_resolver and not test_concurrent_s3fs_init and not test_env_var_io_thread_count']))"; then
    echo "------------------${PACKAGE_NAME}:install_success_but_test_fails---------------------"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | Fail | Test_Fails"
    exit 2
fi
echo "------------------${PACKAGE_NAME}:install_&_test_both_success-------------------------"
exit 0
