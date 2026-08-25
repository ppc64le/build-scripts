#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pyarrow
# Version       : 23.0.1
# Source repo   : https://github.com/apache/arrow
# Tested on     : UBI 8.10
# Language      : Python, C++, Cython
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Amit Kumar <amit.kumar282@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# platform using the mentioned version of the package. It may not work
# as expected with newer versions of the package and/or distribution.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=pyarrow
PACKAGE_DIR=arrow/python
PACKAGE_VERSION=${1:-23.0.1}
PACKAGE_URL=https://github.com/apache/arrow
PACKAGE_VERSION="${PACKAGE_VERSION#apache-arrow-}"
CURRENT_DIR="${PWD}"

# Arrow C++ install prefix
ARROW_HOME="${CURRENT_DIR}/arrow-install"

# Parallel build jobs — use all available CPUs
NPROC=$(nproc)

# -----------------------------------------------------------------------------
# 1. Install system dependencies
# -----------------------------------------------------------------------------

yum install -y python3.12 python3.12-devel python3.12-pip git make cmake ninja-build binutils wget unzip autoconf automake libtool pkg-config gcc-toolset-13 gcc-toolset-13-binutils gcc-toolset-13-binutils-devel gcc-toolset-13-gcc-c++ gcc-toolset-13-libatomic-devel openssl-devel zlib-devel bzip2-devel lz4-devel libcurl-devel

# UBI 8.10 ships GCC 8.5; GCC Toolset 13 provides GCC 13.
source /opt/rh/gcc-toolset-13/enable

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:${LD_LIBRARY_PATH:-}

echo "GCC version  : $(gcc --version | head -1)"
echo "G++ version  : $(g++ --version | head -1)"
echo "CMake version: $(cmake --version | head -1)"
echo "Python version: $(python3.12 --version)"

# -----------------------------------------------------------------------------
# 2. Clone source repository
# -----------------------------------------------------------------------------

cd "$CURRENT_DIR"
[ -d "arrow" ] && rm -rf "arrow"
git clone "$PACKAGE_URL" arrow
cd arrow
git checkout "apache-arrow-${PACKAGE_VERSION}"
git submodule update --init --recursive

# -----------------------------------------------------------------------------
# 3. Set package version
# -----------------------------------------------------------------------------

echo "Package version : ${PACKAGE_VERSION}"

# -----------------------------------------------------------------------------
# 4. Create Python virtual environment
# -----------------------------------------------------------------------------

cd "$CURRENT_DIR"

PYTHON_BIN=$(command -v python3.12)

"${PYTHON_BIN}" -m venv pyarrow-env
source pyarrow-env/bin/activate

PYTHON_BIN="${VIRTUAL_ENV}/bin/python"

echo "Using Python    : ${PYTHON_BIN}"
echo "Python version  : $(${PYTHON_BIN} --version)"

# -----------------------------------------------------------------------------
# 5. Install Python build dependencies
# -----------------------------------------------------------------------------

"${PYTHON_BIN}" -m pip install --upgrade pip wheel setuptools

"${PYTHON_BIN}" -m pip install "numpy>=1.26,<3" "cython>=3.0,<4" "setuptools_scm[toml]>=8" pytest build auditwheel patchelf

# -----------------------------------------------------------------------------
# 6. Configure Power CPU compiler flags
#
# -mcpu=power9 -mtune=power9
#   Generates code valid on Power9, Power10, and Power11.
#   Does NOT use -mcpu=native or any Power10/Power11-exclusive VSX4/MMA
#   instructions, so the wheel is portable across the whole ppc64le fleet.
# -----------------------------------------------------------------------------

export CFLAGS="-mcpu=power9 -mtune=power9 -O2"
export CXXFLAGS="-mcpu=power9 -mtune=power9 -O2"
export CPPFLAGS="${CFLAGS}"

echo "CFLAGS  = ${CFLAGS}"
echo "CXXFLAGS= ${CXXFLAGS}"

# -----------------------------------------------------------------------------
# 7. Build Arrow C++ with CMake
# -----------------------------------------------------------------------------

mkdir -p "${CURRENT_DIR}/arrow-build"
cd "${CURRENT_DIR}/arrow-build"

cmake \
    "${CURRENT_DIR}/arrow/cpp" \
    -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${ARROW_HOME}" \
    -DCMAKE_C_COMPILER=gcc \
    -DCMAKE_CXX_COMPILER=g++ \
    -DCMAKE_C_FLAGS="${CFLAGS}" \
    -DCMAKE_CXX_FLAGS="${CXXFLAGS}" \
    \
    -DBUILD_SHARED_LIBS=ON \
    -DARROW_BUILD_STATIC=OFF \
    \
    -DARROW_PYTHON=ON \
    -DARROW_PARQUET=ON \
    -DARROW_DATASET=ON \
    -DARROW_FILESYSTEM=ON \
    -DARROW_COMPUTE=ON \
    -DARROW_CSV=ON \
    -DARROW_JSON=ON \
    -DARROW_IPC=ON \
    -DARROW_FLIGHT=ON \
    -DARROW_FLIGHT_SQL=ON \
    \
    -DARROW_GANDIVA=OFF \
    -DARROW_PLASMA=OFF \
    -DARROW_ORC=OFF \
    \
    -DARROW_WITH_LZ4=ON \
    -DARROW_WITH_ZSTD=ON \
    -DARROW_WITH_SNAPPY=ON \
    -DARROW_WITH_BROTLI=ON \
    -DARROW_WITH_ZLIB=ON \
    -DARROW_WITH_BZ2=ON \
    \
    -DARROW_DEPENDENCY_SOURCE=BUNDLED \
    \
    -DARROW_SIMD_LEVEL=NONE \
    -DARROW_ALTIVEC=ON \
    \
    -DARROW_BUILD_TESTS=OFF \
    -DARROW_BUILD_BENCHMARKS=OFF \
    -DARROW_BUILD_EXAMPLES=OFF \
    \
    -DPARQUET_BUILD_EXECUTABLES=OFF \
    -DPARQUET_BUILD_EXAMPLES=OFF \
    \
    -DPYTHON_EXECUTABLE="${PYTHON_BIN}" \
    -DPython3_EXECUTABLE="${PYTHON_BIN}" \
    \
    -DCMAKE_INSTALL_RPATH="${ARROW_HOME}/lib64:${ARROW_HOME}/lib" \
    -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON

echo "--- Arrow C++ CMake configure complete ---"

cmake --build . --parallel "${NPROC}"

echo "--- Arrow C++ build complete ---"

cmake --install .

echo "--- Arrow C++ install complete (prefix: ${ARROW_HOME}) ---"

# -----------------------------------------------------------------------------
# 8. Build pyarrow wheel
# -----------------------------------------------------------------------------

cd "${CURRENT_DIR}/${PACKAGE_DIR}"

export ARROW_HOME="${ARROW_HOME}"
export PYARROW_WITH_PARQUET=1
export PYARROW_WITH_DATASET=1
export PYARROW_WITH_FLIGHT=1
export PYARROW_WITH_FLIGHT_SQL=1
export PYARROW_WITH_GANDIVA=0
export PYARROW_WITH_ORC=0
export PYARROW_WITH_PLASMA=0
export PYARROW_PARALLEL="${NPROC}"

export SETUPTOOLS_SCM_PRETEND_VERSION="${PACKAGE_VERSION}"

export LD_LIBRARY_PATH="${ARROW_HOME}/lib64:${ARROW_HOME}/lib:${LD_LIBRARY_PATH:-}"
export PKG_CONFIG_PATH="${ARROW_HOME}/lib64/pkgconfig:${ARROW_HOME}/lib/pkgconfig:${PKG_CONFIG_PATH:-}"

# Tell pyarrow's cmake where to find ArrowConfig.cmake
export CMAKE_PREFIX_PATH="${ARROW_HOME}"
export PYARROW_CMAKE_OPTIONS="-DCMAKE_PREFIX_PATH=${ARROW_HOME}"

if "${PYTHON_BIN}" -m build --wheel --no-isolation; then
    echo "------------------${PACKAGE_NAME}::Build_Pass---------------------"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | Pass | Build_Success"
else
    echo "------------------${PACKAGE_NAME}::Build_Fail---------------------"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | Fail | Build_Fail"
    exit 1
fi

# -----------------------------------------------------------------------------
# 9. Verify source wheel
# -----------------------------------------------------------------------------

SOURCE_WHEEL=$(ls dist/pyarrow-*.whl 2>/dev/null | head -1)

if [ -z "${SOURCE_WHEEL}" ] || [ ! -f "${SOURCE_WHEEL}" ]; then
    echo "ERROR: pyarrow source wheel not found in $(pwd)/dist/"
    exit 1
fi

echo "Source wheel: ${SOURCE_WHEEL}"

# -----------------------------------------------------------------------------
# 10. Run auditwheel repair
# -----------------------------------------------------------------------------

mkdir -p wheelhouse
rm -f wheelhouse/pyarrow-*.whl

echo "Running auditwheel repair..."

if auditwheel repair --plat manylinux_2_28_ppc64le --wheel-dir wheelhouse "${SOURCE_WHEEL}"; then
    echo "------------------${PACKAGE_NAME}::Auditwheel_Pass---------------------"
    echo "Auditwheel repair successful"
else
    echo "------------------${PACKAGE_NAME}::Auditwheel_Fail---------------------"
    echo "Auditwheel repair failed"
    exit 1
fi

# -----------------------------------------------------------------------------
# 11. Find repaired wheel
# -----------------------------------------------------------------------------

DUAL_WHEEL=$(ls wheelhouse/pyarrow-*.whl 2>/dev/null | head -1)

if [ -z "${DUAL_WHEEL}" ] || [ ! -f "${DUAL_WHEEL}" ]; then
    echo "ERROR: Repaired pyarrow wheel not found"
    exit 1
fi

echo "Auditwheel generated wheel: ${DUAL_WHEEL}"

# -----------------------------------------------------------------------------
# 12. Extract version, Python and ABI tags from SOURCE_WHEEL
#
# Example SOURCE_WHEEL:
#   pyarrow-23.0.1-cp312-cp312-linux_ppc64le.whl
# -----------------------------------------------------------------------------

SOURCE_BASENAME=$(basename "${SOURCE_WHEEL}")

VERSION=$(echo "${SOURCE_BASENAME}" | cut -d'-' -f2)
PYTHON_TAG=$(echo "${SOURCE_BASENAME}" | cut -d'-' -f3)
ABI_TAG=$(echo "${SOURCE_BASENAME}" | cut -d'-' -f4)

echo "Version    : ${VERSION}"
echo "Python tag : ${PYTHON_TAG}"
echo "ABI tag    : ${ABI_TAG}"

if [ -z "${VERSION}" ] || [ -z "${PYTHON_TAG}" ] || [ -z "${ABI_TAG}" ]; then
    echo "ERROR: Unable to extract wheel metadata from source wheel filename"
    exit 1
fi

# -----------------------------------------------------------------------------
# 13. Construct required final wheel name
# -----------------------------------------------------------------------------

FINAL_WHEEL="wheelhouse/pyarrow-${VERSION}-${PYTHON_TAG}-${ABI_TAG}-manylinux_2_28_ppc64le.whl"

echo "Final wheel: ${FINAL_WHEEL}"

# -----------------------------------------------------------------------------
# 14. Rename auditwheel-generated wheel if necessary
# -----------------------------------------------------------------------------

if [ "${DUAL_WHEEL}" != "${FINAL_WHEEL}" ]; then

    if [ -f "${FINAL_WHEEL}" ]; then
        echo "ERROR: Final wheel already exists: ${FINAL_WHEEL}"
        exit 1
    fi

    mv "${DUAL_WHEEL}" "${FINAL_WHEEL}"
    echo "Renamed wheel: $(basename "${FINAL_WHEEL}")"

else
    echo "Wheel already has the expected filename: $(basename "${FINAL_WHEEL}")"
fi

if [ ! -f "${FINAL_WHEEL}" ]; then
    echo "ERROR: Final wheel not found: ${FINAL_WHEEL}"
    exit 1
fi

echo "Final wheel ready: ${FINAL_WHEEL}"

# -----------------------------------------------------------------------------
# 15. Install generated wheel
# -----------------------------------------------------------------------------

cd "${CURRENT_DIR}/${PACKAGE_DIR}"

if "${PYTHON_BIN}" -m pip install --only-binary=:all: "${FINAL_WHEEL}"; then
    echo "------------------${PACKAGE_NAME}::Install_Pass---------------------"
else
    echo "------------------${PACKAGE_NAME}::Install_Fail---------------------"
    exit 1
fi

# -----------------------------------------------------------------------------
# 16. Test installed pyarrow
# -----------------------------------------------------------------------------

cd "$CURRENT_DIR"

"${PYTHON_BIN}" -m pip show pyarrow

"${PYTHON_BIN}" -c "
import pyarrow as pa
import pyarrow.parquet as pq
import pyarrow.dataset as ds
import pyarrow.flight as fl
import pyarrow.compute as pc
import numpy as np
import tempfile, os

print('pyarrow version  :', pa.__version__)
print('Arrow C++ version:', pa.cpp_version)
print('Location         :', pa.__file__)

arr = pa.array([1, 2, 3, 4, 5], type=pa.int64())
assert arr.to_pylist() == [1, 2, 3, 4, 5], 'array to_pylist mismatch'
assert pc.sum(arr).as_py() == 15,           'compute sum mismatch'

tbl = pa.table({'a': pa.array(range(100)), 'b': pa.array(range(100, 200))})
assert tbl.num_rows == 100,  'table row count mismatch'
assert tbl.num_columns == 2, 'table column count mismatch'

with tempfile.TemporaryDirectory() as tmpdir:
    pq_path = os.path.join(tmpdir, 'test.parquet')
    pq.write_table(tbl, pq_path)
    tbl2 = pq.read_table(pq_path)
    assert tbl2.equals(tbl), 'Parquet round-trip data mismatch'
    print('Parquet round-trip: OK')

sink = pa.BufferOutputStream()
writer = pa.ipc.new_stream(sink, tbl.schema)
writer.write_table(tbl)
writer.close()
buf = sink.getvalue()
reader = pa.ipc.open_stream(buf)
tbl3 = reader.read_all()
assert tbl3.equals(tbl), 'IPC round-trip data mismatch'
print('IPC round-trip   : OK')

np_col = tbl.column('a').to_pylist()
assert np_col[0] == 0, 'NumPy interop mismatch'
print('NumPy interop    : OK')

print()
print('All pyarrow smoke tests PASSED.')
"

if [ $? -eq 0 ]; then
    echo "------------------${PACKAGE_NAME}::Test_Pass---------------------"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | Pass | Test_Success"
    deactivate
    exit 0
else
    echo "------------------${PACKAGE_NAME}::Test_Fail---------------------"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | Fail | Test_Fail"
    deactivate
    exit 2
fi
