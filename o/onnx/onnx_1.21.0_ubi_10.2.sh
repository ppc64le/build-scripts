#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : onnx
# Version          : 1.21.0
# Source repo      : https://github.com/onnx/onnx
# Tested on        : UBI:10.2
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Siddesh Sangodkar <siddesh.sangodkar1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#

# -----------------------------------------------------------------------------

set -e

PACKAGE_NAME=onnx
PACKAGE_VERSION=${1:-v1.21.0}
PACKAGE_VERSION="${PACKAGE_VERSION#v}"
PACKAGE_URL=https://github.com/onnx/onnx
CURRENT_DIR=$(pwd)
WHEEL_DIR="${CURRENT_DIR}/wheels"
mkdir -p "${WHEEL_DIR}"

NUMPY_VERSION="2.5.0"
ML_DTYPES_VERSION="0.6.0"
XGBOOST_VERSION="3.4.0"
PYARROW_VERSION_VAL="25.0.0"
LIGHTGBM_VERSION="4.7.0"
IBM_WHEELS="https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/"
IBM_WHEELS_HOST="wheels.developerfirst.ibm.com"

# ---------------------------------------------------------------------------
# System dependencies
# ---------------------------------------------------------------------------
yum install -y python3.14 python3.14-devel python3.14-pip \
    git gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ \
    gcc-toolset-15-gcc-gfortran gcc-toolset-15-libatomic-devel \
    cmake ninja-build make \
    openblas-devel \
    libatomic \
    pkg-config \
    openssl-devel libffi-devel zlib-devel \
    which curl tar

# UBI 10 dropped SCL — guard block
if [[ -f /opt/rh/gcc-toolset-15/enable ]]; then
    source /opt/rh/gcc-toolset-15/enable
elif [[ -d /opt/rh/gcc-toolset-15/root/usr/bin ]]; then
    export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"
    export LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64:$LD_LIBRARY_PATH"
else
    echo "ERROR: gcc-toolset-15 not found"
    exit 1
fi

echo "Using gcc:    $(gcc --version | head -1)"
echo "Using cmake:  $(cmake --version | head -1)"
echo "Using ninja:  $(ninja --version)"
echo "Using python: $(python3.14 --version)"

# ---------------------------------------------------------------------------
# Python build tools
# ---------------------------------------------------------------------------
python3.14 -m pip install --upgrade pip setuptools wheel build
python3.14 -m pip install pytest parameterized onnxscript "meson-python>=0.18.0" "Cython>=3.0.6" meson ninja patchelf "numpy==${NUMPY_VERSION}" "protobuf==6.33.6"

# scipy 1.18.0, scikit-learn 1.9.0 — IBM wheels
python3.14 -m pip install \
    --trusted-host "${IBM_WHEELS_HOST}" \
    --extra-index-url "${IBM_WHEELS}" \
    --prefer-binary \
      "scipy==1.18.0" \
      "torch==2.13.0" \
      "onnxruntime==1.26.0" \
    "scikit-learn==1.9.0"


cd "${CURRENT_DIR}"

# ml_dtypes — 0.6.0 not on IBM index; build from source (scikit-build-core)
python3.14 -m pip install "scikit-build-core" "pybind11" "typing_extensions>=4.7.1"

ML_DTYPES_SDIST="https://files.pythonhosted.org/packages/12/72/307d7c4bd0600601c7133fba5cb78af7db968152951c1cd473abb1cda782/ml_dtypes-${ML_DTYPES_VERSION}.tar.gz"
python3.14 -m pip install --no-build-isolation "${ML_DTYPES_SDIST}"


# ---------------------------------------------------------------------------
# Download onnx 1.21.0 sdist from PyPI
# ---------------------------------------------------------------------------
SDIST_URL="https://files.pythonhosted.org/packages/source/o/onnx/onnx-${PACKAGE_VERSION}.tar.gz"
cd "${CURRENT_DIR}"
curl -sSL --fail -o "onnx-${PACKAGE_VERSION}.tar.gz" "${SDIST_URL}"
tar -xzf "onnx-${PACKAGE_VERSION}.tar.gz"
cd "onnx-${PACKAGE_VERSION}"

# ---------------------------------------------------------------------------
# Build onnx wheel
#
# ONNX_BUILD_CUSTOM_PROTOBUF=ON  — CMake fetches protobuf 31.1 (+ abseil)
#                                  via FetchContent; no system protobuf needed.
# USE_NINJA=1                    — use Ninja for faster parallel compilation.
# MAX_JOBS                       — parallelism cap.
# ---------------------------------------------------------------------------
export ONNX_BUILD_CUSTOM_PROTOBUF=ON
export USE_NINJA=1
export MAX_JOBS=$(nproc)

if ! python3.14 -m build --wheel --no-isolation --outdir="${WHEEL_DIR}"; then
    echo "------------------$PACKAGE_NAME:Build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

cp "${WHEEL_DIR}"/*.whl "${CURRENT_DIR}/" 2>/dev/null || true

# ---------------------------------------------------------------------------
# Install built wheel
# ---------------------------------------------------------------------------
cd "${CURRENT_DIR}"
WHL=$(ls "${CURRENT_DIR}"/onnx-*.whl "${WHEEL_DIR}"/onnx-*.whl 2>/dev/null | head -1)
python3.14 -m pip install --no-build-isolation --no-deps --force-reinstall "${WHL}"


   

# ---------------------------------------------------------------------------
# xgboost 3.4.0 — not on IBM index; build from source sdist (scikit-build-core)
# ---------------------------------------------------------------------------
XGBOOST_SDIST="https://files.pythonhosted.org/packages/7d/11/2b1de4cb9b7eeb042ca49c7d3b3ed2b77e7645ee6c0f99cf616716f3e8d7/xgboost-${XGBOOST_VERSION}.tar.gz"

python3.14 -m pip install --no-build-isolation "${XGBOOST_SDIST}"

# ---------------------------------------------------------------------------
# pyarrow 25.0.0 — not on IBM index; build Arrow C++ from source, then pyarrow.
# The pyarrow sdist only ships Python bindings; Arrow C++ must be pre-installed.
# ---------------------------------------------------------------------------
PYARROW_SDIST="https://files.pythonhosted.org/packages/27/f3/95428098d1fa7d04432fb750eed06b41304c2f6a5d3319985e64db2d9d41/pyarrow-${PYARROW_VERSION_VAL}.tar.gz"

    # gcc-toolset-15 ld searches its own lib directory and does not find the
    # system libatomic.  Create the unversioned symlink that -latomic requires.
    if [[ ! -e /usr/lib64/libatomic.so ]]; then
        ln -s /usr/lib64/libatomic.so.1 /usr/lib64/libatomic.so
        echo "Created /usr/lib64/libatomic.so symlink for Arrow C++ build"
    fi

    # Step 1: Build and install Arrow C++ 25.0.0
    ARROW_TARBALL="https://archive.apache.org/dist/arrow/arrow-${PYARROW_VERSION_VAL}/apache-arrow-${PYARROW_VERSION_VAL}.tar.gz"
    ARROW_SRC="${CURRENT_DIR}/arrow_src"
    mkdir -p "${ARROW_SRC}"
    curl -sSL --fail -o "${ARROW_SRC}/apache-arrow-${PYARROW_VERSION_VAL}.tar.gz" "${ARROW_TARBALL}"
    tar -xzf "${ARROW_SRC}/apache-arrow-${PYARROW_VERSION_VAL}.tar.gz" -C "${ARROW_SRC}"
    ARROW_CPP_SRC="${ARROW_SRC}/apache-arrow-${PYARROW_VERSION_VAL}/cpp"

    mkdir -p "${ARROW_CPP_SRC}/build"
    cmake -S "${ARROW_CPP_SRC}" -B "${ARROW_CPP_SRC}/build" \
        -GNinja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DCMAKE_EXE_LINKER_FLAGS="-L/usr/lib64" \
        -DCMAKE_SHARED_LINKER_FLAGS="-L/usr/lib64" \
        -DCMAKE_MODULE_LINKER_FLAGS="-L/usr/lib64" \
        -DARROW_BUILD_STATIC=OFF \
        -DARROW_BUILD_SHARED=ON \
        -DARROW_PYTHON=ON \
        -DARROW_DATASET=ON \
        -DARROW_PARQUET=ON \
        -DARROW_ACERO=ON \
        -DARROW_COMPUTE=ON \
        -DARROW_CSV=ON \
        -DARROW_JSON=ON \
        -DARROW_IPC=ON \
        -DARROW_WITH_ZLIB=ON \
        -DARROW_WITH_LZ4=ON \
        -DARROW_WITH_SNAPPY=ON \
        -DARROW_WITH_ZSTD=ON \
        -DARROW_WITH_BZ2=ON \
        -DARROW_DEPENDENCY_SOURCE=BUNDLED \
        -DARROW_VERBOSE_THIRDPARTY_BUILD=OFF
    cmake --build "${ARROW_CPP_SRC}/build" --parallel "$(nproc)"
    cmake --install "${ARROW_CPP_SRC}/build"
    ldconfig
    export Arrow_DIR=/usr/local/lib/cmake/Arrow
    export ArrowDataset_DIR=/usr/local/lib/cmake/ArrowDataset
    export Parquet_DIR=/usr/local/lib/cmake/Parquet
    # Arrow C++ installs to /usr/local/lib (and /usr/local/lib64 on some builds).
    # Export both so pyarrow can dlopen libarrow*.so at validation time.
    export LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib64:${LD_LIBRARY_PATH:-}
    # Persist via ldconfig so the path survives across subshell boundaries.
    echo "/usr/local/lib"    > /etc/ld.so.conf.d/arrow-local.conf
    echo "/usr/local/lib64" >> /etc/ld.so.conf.d/arrow-local.conf
    ldconfig

    # Step 2: Build pyarrow against the installed Arrow C++
    python3.14 -m pip install "scikit-build-core>=0.11.0" cython "setuptools_scm[toml]>=8"
    export PYARROW_REQUIRE_STUB_DOCSTRINGS=OFF
    export CMAKE_BUILD_PARALLEL_LEVEL=$(nproc)
python3.14 -m pip install --no-build-isolation "${PYARROW_SDIST}"


# ---------------------------------------------------------------------------
# lightgbm 4.7.0 — not on IBM index; build from source sdist (scikit-build-core)
# Preload libgomp to work around ppc64le static TLS allocation error with ctypes
# ---------------------------------------------------------------------------
LIGHTGBM_SDIST="https://files.pythonhosted.org/packages/63/8e/4db5e29290d7e619c307fdb8dab0a0514090af2ce3ec483050e024ec6126/lightgbm-${LIGHTGBM_VERSION}.tar.gz"
python3.14 -m pip install --no-build-isolation "${LIGHTGBM_SDIST}"
LIBGOMP=$(find /opt/rh/gcc-toolset-15/root/usr/lib64 /usr/lib64 -name "libgomp.so*" 2>/dev/null | head -1)
[[ -n "${LIBGOMP}" ]] && export LD_PRELOAD="${LIBGOMP}" && echo "Preloading ${LIBGOMP} for lightgbm TLS fix"

# ---------------------------------------------------------------------------
# run tests
# ---------------------------------------------------------------------------
cd "${CURRENT_DIR}/onnx-${PACKAGE_VERSION}"

if ! pytest --ignore=onnx/test/reference_evaluator_test.py --ignore=onnx/test/test_backend_reference.py --ignore=onnx/test/reference_evaluator_backend_test.py ; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
