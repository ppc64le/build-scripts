#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : scikit-learn
# Version       : 1.9.0
# Source repo   : https://github.com/scikit-learn/scikit-learn.git
# Tested on     : UBI 10.1
# Language      : Python, Cython, C++
# Ci-Check      : True
# Script License: Apache License 2.0
# Maintainer    : Varsha Kumar <varsha.kumar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

# Variables
PACKAGE_DIR="scikit-learn"
PACKAGE_NAME="scikit_learn"
PACKAGE_VERSION=${1:-1.9.0}
PACKAGE_URL="https://github.com/scikit-learn/scikit-learn.git"
SOURCE_ROOT="$(pwd)"

echo "Building ${PACKAGE_NAME} ${PACKAGE_VERSION}"

# Install system dependencies
dnf install -y gcc-toolset-15 gcc-toolset-15-gcc-c++ gcc-toolset-15-gcc-gfortran \
    git python3.12 python3.12-devel python3.12-pip pkg-config \
    openblas-devel

export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"

# Verify GCC version (scikit-learn requires >= 8.0)
gcc --version

# Install build dependencies
# pythran is required by scipy>=1.17 at build time
python3.12 -m pip install \
    "meson-python>=0.17.1,<0.20.0" \
    "meson>=1.9.0" \
    "ninja" \
    "cython>=3.1.2,<3.3.0" \
    "numpy>=2,<2.5.0" \
    "pythran" \
    "pybind11>=2.13.2" \
    "wheel"

# Build and install scipy separately so the pythran dep is satisfied
python3.12 -m pip install --no-build-isolation "scipy>=1.10.0,<1.18.0"

# Clone and checkout
rm -rf "$PACKAGE_DIR"
git clone "$PACKAGE_URL"
cd "${PACKAGE_DIR}"
git checkout "${PACKAGE_VERSION}"

# Build wheel using pip with no-build-isolation
# (meson-python builds require access to already-installed build deps)
python3.12 -m pip wheel . \
    --no-build-isolation \
    --wheel-dir "${SOURCE_ROOT}/dist/"

WHEEL=$(find "${SOURCE_ROOT}/dist" -name "${PACKAGE_NAME}-*.whl" | head -1)
if [ -z "$WHEEL" ]; then
    echo "ERROR: wheel not found after build"
    exit 1
fi
echo "Wheel: $WHEEL"

# Copy wheel to /home/tester/ to avoid rebuild by wrapper script
mkdir -p /home/tester
cp "$WHEEL" /home/tester/

cd "${SOURCE_ROOT}"

# Install runtime dependencies and wheel
echo "=== Installing Wheel ==="
python3.12 -m pip install \
    "joblib>=1.4.0" \
    "narwhals>=2.0.1" \
    "threadpoolctl>=3.5.0"
python3.12 -m pip install "$WHEEL"

# Test
echo "=== Running Tests ==="

# 1. Version check
python3.12 -c "import importlib.metadata; print('version:', importlib.metadata.version('scikit-learn'))"

# 2. Basic smoke test
python3.12 - <<'EOF'
import sklearn
print("sklearn version:", sklearn.__version__)
assert sklearn.__version__ == "1.9.0", f"Unexpected version: {sklearn.__version__}"

from sklearn.datasets import load_iris
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score

X, y = load_iris(return_X_y=True)
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

clf = RandomForestClassifier(n_estimators=10, random_state=42)
clf.fit(X_train, y_train)
preds = clf.predict(X_test)
acc = accuracy_score(y_test, preds)
assert acc > 0.9, f"Accuracy too low: {acc}"
print(f"RandomForest smoke test: OK (accuracy={acc:.2f})")

from sklearn.linear_model import LogisticRegression
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler

pipe = Pipeline([("scaler", StandardScaler()), ("lr", LogisticRegression(max_iter=200))])
pipe.fit(X_train, y_train)
pipe_acc = accuracy_score(y_test, pipe.predict(X_test))
assert pipe_acc > 0.9, f"Pipeline accuracy too low: {pipe_acc}"
print(f"Pipeline smoke test: OK (accuracy={pipe_acc:.2f})")
EOF

# 3. Run upstream test suite (core module only to keep CI time reasonable)
echo "=== Running Upstream Tests ==="
python3.12 -m pip install pytest

# Resolve the installed sklearn path so pytest uses the compiled wheel,
# not the unbuilt source clone (which lacks the _check_build compiled extension).
SKLEARN_PATH=$(python3.12 -c "import sklearn; import os; print(os.path.dirname(sklearn.__file__))")
python3.12 -m pytest "${SKLEARN_PATH}/tests/test_common.py" -x -q --no-header

echo -e "\n=== Build Complete ==="
echo "Wheel: $WHEEL"
