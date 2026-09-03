#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : scikit-learn
# Version       : 1.9.0
# Source repo   : https://github.com/scikit-learn/scikit-learn.git
# Tested on     : UBI 10.2
# Language      : Python, Cython, C++
# Ci-Check      : True
# Script License: Apache License 2.0
# Maintainer    : Sakshi Jain <sakshi.jain16@ibm.com>
#
# -----------------------------------------------------------------------------

PACKAGE_NAME="scikit-learn"
PACKAGE_VERSION=${1:-1.9.0}
PACKAGE_URL="https://github.com/scikit-learn/scikit-learn.git"

OPENBLAS_VERSION="v0.3.33"
OPENBLAS_URL="https://github.com/OpenMathLib/OpenBLAS"

CURRENT_DIR="${PWD}"
INSTALL_ROOT="/install-deps"
OPENBLAS_PREFIX="${INSTALL_ROOT}/openblas"
DIST_DIR="/dist"

MAX_JOBS=${MAX_JOBS:-8}

GCC_HOME="/opt/rh/gcc-toolset-15/root/usr"

echo "============================================================"
echo "Building ${PACKAGE_NAME} ${PACKAGE_VERSION}"
echo "============================================================"

# -----------------------------------------------------------------------------
# Install system dependencies
# -----------------------------------------------------------------------------

yum install -y \
    git \
    make \
    pkgconfig \
    gcc-toolset-15 \
    gcc-toolset-15-binutils \
    gcc-toolset-15-binutils-devel \
    gcc-toolset-15-gcc-c++ \
    gcc-toolset-15-gcc-gfortran \
    python3.14 \
    python3.14-pip \
    python3.14-devel

# -----------------------------------------------------------------------------
# GCC Toolset 15
# -----------------------------------------------------------------------------

export PATH="${GCC_HOME}/bin:${PATH}"
export LD_LIBRARY_PATH="${GCC_HOME}/lib64:${LD_LIBRARY_PATH:-}"

export CC="${GCC_HOME}/bin/gcc"
export CXX="${GCC_HOME}/bin/g++"
export FC="${GCC_HOME}/bin/gfortran"

gcc --version

# -----------------------------------------------------------------------------
# Python build dependencies
# -----------------------------------------------------------------------------

python3.14 -m pip install --upgrade pip

python3.14 -m pip install \
    setuptools==77.0.1 \
    wheel \
    ninja \
    meson \
    "meson-python>=0.17.1,<0.20.0" \
    "cython>=3.1.2,<3.3.0" \
    pythran \
    "pybind11>=2.13.2" \
    pytest

# -----------------------------------------------------------------------------
# Build OpenBLAS 0.3.33
# -----------------------------------------------------------------------------

mkdir -p "${OPENBLAS_PREFIX}"

cd "${CURRENT_DIR}"
rm -rf OpenBLAS

echo "============================================================"
echo "Building OpenBLAS ${OPENBLAS_VERSION}"
echo "============================================================"

git clone "${OPENBLAS_URL}"

cd OpenBLAS
git checkout "${OPENBLAS_VERSION}"
git submodule update --init

export USE_OPENMP=1
export USE_THREAD=1
export NUM_THREADS="${MAX_JOBS}"
export TARGET=POWER9
export DYNAMIC_ARCH=1
export INTERFACE64=0
export BUILD_BFLOAT16=1
export NO_AFFINITY=1

export CF="${CFLAGS:-} -Wno-unused-parameter -Wno-old-style-declaration"
unset CFLAGS

export LDFLAGS="$(echo "${LDFLAGS:-}" | sed 's/-Wl,--gc-sections//g')"

if [ -n "${FFLAGS:-}" ]; then
    export FFLAGS="${FFLAGS/-fopenmp/ }"
    export FFLAGS="${FFLAGS} -frecursive"
    export LAPACK_FFLAGS="${FFLAGS}"
fi

make -j"${MAX_JOBS}" \
    TARGET="${TARGET}" \
    BUILD_BFLOAT16="${BUILD_BFLOAT16}" \
    BINARY=64 \
    USE_OPENMP="${USE_OPENMP}" \
    USE_THREAD="${USE_THREAD}" \
    NUM_THREADS="${NUM_THREADS}" \
    DYNAMIC_ARCH="${DYNAMIC_ARCH}" \
    INTERFACE64="${INTERFACE64}" \
    NO_AFFINITY="${NO_AFFINITY}" \
    CFLAGS="${CF}" \
    FFLAGS="${FFLAGS:-}"

make install PREFIX="${OPENBLAS_PREFIX}"

# -----------------------------------------------------------------------------
# OpenBLAS environment
# -----------------------------------------------------------------------------

export LD_LIBRARY_PATH="${OPENBLAS_PREFIX}/lib:${OPENBLAS_PREFIX}/lib64:${LD_LIBRARY_PATH:-}"
export PKG_CONFIG_PATH="${OPENBLAS_PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
export CPATH="${OPENBLAS_PREFIX}/include:${CPATH:-}"
export LIBRARY_PATH="${OPENBLAS_PREFIX}/lib:${OPENBLAS_PREFIX}/lib64:${LIBRARY_PATH:-}"

echo "OpenBLAS version:"
pkg-config --modversion openblas || true

# -----------------------------------------------------------------------------
# Install NumPy 2.5.0
# -----------------------------------------------------------------------------

echo "============================================================"
echo "Installing NumPy 2.5.0"
echo "============================================================"

python3.14 -m pip install \
    numpy==2.5.0

python3.14 -c \
    "import numpy; print('NumPy:', numpy.__version__)"

# -----------------------------------------------------------------------------
# Install SciPy 1.18.0
# -----------------------------------------------------------------------------

echo "============================================================"
echo "Installing SciPy 1.18.0"
echo "============================================================"

python3.14 -m pip install \
    scipy==1.18.0 \
    --no-build-isolation \
    --no-deps

python3.14 -c \
    "import scipy; print('SciPy:', scipy.__version__)"

# -----------------------------------------------------------------------------
# Clone scikit-learn
# -----------------------------------------------------------------------------

cd "${CURRENT_DIR}"
rm -rf "${PACKAGE_NAME}"

echo "============================================================"
echo "Cloning scikit-learn ${PACKAGE_VERSION}"
echo "============================================================"

git clone "${PACKAGE_URL}"

cd "${PACKAGE_NAME}"
git checkout "${PACKAGE_VERSION}"

# -----------------------------------------------------------------------------
# Install scikit-learn runtime dependencies
# -----------------------------------------------------------------------------

python3.14 -m pip install \
    "joblib>=1.4.0" \
    "threadpoolctl>=3.5.0" \
    "narwhals>=2.0.1"

# -----------------------------------------------------------------------------
# Verify dependency versions
# -----------------------------------------------------------------------------

echo "============================================================"
echo "Dependency versions"
echo "============================================================"

python3.14 - <<'EOF'
import numpy
import scipy

print("NumPy :", numpy.__version__)
print("SciPy :", scipy.__version__)

assert numpy.__version__ == "2.5.0"
assert scipy.__version__ == "1.18.0"
EOF

# -----------------------------------------------------------------------------
# Build scikit-learn wheel
# -----------------------------------------------------------------------------

cd "${CURRENT_DIR}/${PACKAGE_NAME}"

mkdir -p "${DIST_DIR}"
rm -f "${DIST_DIR}"/scikit_learn-*.whl

echo "============================================================"
echo "Building scikit-learn wheel"
echo "============================================================"

python3.14 -m pip wheel . \
    --no-build-isolation \
    --no-deps \
    --wheel-dir "${DIST_DIR}"

# -----------------------------------------------------------------------------
# Locate generated wheel
# -----------------------------------------------------------------------------

WHEEL=$(find "${DIST_DIR}" \
    -maxdepth 1 \
    -type f \
    -name "scikit_learn-*.whl" \
    | head -1)

if [ -z "${WHEEL}" ]; then
    echo "ERROR: scikit-learn wheel not found"
    exit 1
fi

echo "============================================================"
echo "Generated wheel"
echo "============================================================"
echo "${WHEEL}"

# -----------------------------------------------------------------------------
# Copy wheel
# -----------------------------------------------------------------------------

mkdir -p /home/tester
cp "${WHEEL}" /home/tester/

# -----------------------------------------------------------------------------
# Install generated wheel
# -----------------------------------------------------------------------------

echo "============================================================"
echo "Installing generated wheel"
echo "============================================================"

python3.14 -m pip install \
    --force-reinstall \
    --no-deps \
    "${WHEEL}"


# -----------------------------------------------------------------------------
# Verify installed versions
# -----------------------------------------------------------------------------

# Change to a directory outside the scikit-learn source tree.
# Otherwise Python may import the local source checkout instead of the
# installed wheel, causing __check_build import failures.
cd /tmp

echo "============================================================"
echo "Installed package versions"
echo "============================================================"

python3.14 - <<'EOF'
import os
import numpy
import scipy
import sklearn
import joblib
import threadpoolctl
import narwhals

print("NumPy        :", numpy.__version__)
print("SciPy        :", scipy.__version__)
print("scikit-learn :", sklearn.__version__)
print("joblib       :", joblib.__version__)
print("threadpoolctl:", threadpoolctl.__version__)
print("narwhals     :", narwhals.__version__)
print("sklearn path :", sklearn.__file__)

source_tree = "/home/tester/scikit-learn"

assert not os.path.abspath(sklearn.__file__).startswith(source_tree), \
    f"ERROR: sklearn imported from source tree: {sklearn.__file__}"

assert numpy.__version__ == "2.5.0"
assert scipy.__version__ == "1.18.0"
assert sklearn.__version__ == "1.9.0"

print("scikit-learn installed wheel import: OK")
EOF

# -----------------------------------------------------------------------------
# Smoke tests
# -----------------------------------------------------------------------------

echo "============================================================"
echo "Running smoke tests"
echo "============================================================"

python3.14 - <<'EOF'
from sklearn.datasets import load_iris
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler

X, y = load_iris(return_X_y=True)

X_train, X_test, y_train, y_test = train_test_split(
    X,
    y,
    test_size=0.2,
    random_state=42
)

# RandomForest test
clf = RandomForestClassifier(
    n_estimators=10,
    random_state=42
)

clf.fit(X_train, y_train)

acc = accuracy_score(
    y_test,
    clf.predict(X_test)
)

assert acc > 0.9, f"RandomForest accuracy too low: {acc}"

print(f"RandomForest smoke test: OK (accuracy={acc:.2f})")

# Pipeline test
pipe = Pipeline([
    ("scaler", StandardScaler()),
    ("lr", LogisticRegression(max_iter=200))
])

pipe.fit(X_train, y_train)

pipe_acc = accuracy_score(
    y_test,
    pipe.predict(X_test)
)

assert pipe_acc > 0.9, f"Pipeline accuracy too low: {pipe_acc}"

print(f"Pipeline smoke test: OK (accuracy={pipe_acc:.2f})")

print("All smoke tests passed.")
EOF

# -----------------------------------------------------------------------------
# Complete
# -----------------------------------------------------------------------------

echo ""
echo "============================================================"
echo "Build Complete"
echo "============================================================"
echo "Package      : ${PACKAGE_NAME}"
echo "Version      : ${PACKAGE_VERSION}"
echo "Wheel        : ${WHEEL}"
echo "============================================================"