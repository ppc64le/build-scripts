#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : langgraph
# Version          : 1.0.9
# Source repo      : https://github.com/langchain-ai/langgraph
# Tested on        : UBI:9.7
# Language         : Python
# Ci-Check         : True
# Script License   : MIT License
# Maintainer       : Amit Kumar <amit.kumar282@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Notes : LangGraph is a monorepo. Sub-packages must be built in order:
#         libs/checkpoint
#         libs/checkpoint-sqlite
#         libs/checkpoint-postgres
#         libs/prebuilt
#         libs/sdk-py
# -----------------------------------------------------------------------------

PACKAGE_NAME=langgraph
PACKAGE_VERSION=${1:-1.0.9}
PACKAGE_URL=https://github.com/langchain-ai/langgraph
CURRENT_DIR=${PWD}

PACKAGE_DIR=langgraph/libs/langgraph

# ---------------------------------------------------------------------------
# 1. Install system dependencies
# ---------------------------------------------------------------------------

yum install -y \
    git make cmake zip tar wget \
    python3.12 python3.12-devel python3.12-pip \
    gcc-toolset-13 gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc \
    zlib-devel libjpeg-devel openssl openssl-devel freetype-devel \
    pkgconfig diffutils libyaml-devel \
    rust cargo \
    gettext \
    sqlite-devel \
    libpq-devel

source /opt/rh/gcc-toolset-13/enable

# ---------------------------------------------------------------------------
# 2. Python tooling
# ---------------------------------------------------------------------------

python3.12 -m pip install --upgrade pip setuptools wheel --root-user-action=ignore
python3.12 -m pip install uv maturin build --root-user-action=ignore

# Prevent grpc build instability
export GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=1
export GRPC_PYTHON_BUILD_SYSTEM_ZLIB=1
export GRPC_PYTHON_BUILD_SYSTEM_CARES=1
export GRPC_PYTHON_BUILD_EXT_COMPILER_JOBS=1

# Prefer wheels wherever available
export PIP_PREFER_BINARY=1

# ---------------------------------------------------------------------------
# 3. Clone repository
# ---------------------------------------------------------------------------

cd "$CURRENT_DIR"
[ -d "$PACKAGE_NAME" ] && rm -rf "$PACKAGE_NAME"

git clone "$PACKAGE_URL"
cd "$PACKAGE_NAME"
git checkout "$PACKAGE_VERSION"

PY_VERSION=$(python3.12 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
export UV_PYTHON="python${PY_VERSION}"

# ---------------------------------------------------------------------------
# 4. Build langgraph-checkpoint
# ---------------------------------------------------------------------------

cd "$CURRENT_DIR/$PACKAGE_NAME/libs/checkpoint"

if ! python3.12 -m pip install . --root-user-action=ignore --prefer-binary; then
    echo "------------------$PACKAGE_NAME:checkpoint_install_fails---------------------"
    exit 1
fi

# ---------------------------------------------------------------------------
# 5. Build sqlite-vec from source
# ---------------------------------------------------------------------------

cd "$CURRENT_DIR"
[ -d sqlite-vec ] && rm -rf sqlite-vec

git clone --depth=1 --branch v0.1.6 https://github.com/asg017/sqlite-vec.git
cd sqlite-vec

PYTHON=python3.12 make loadable

SVPKG="$CURRENT_DIR/sqlite-vec-py"
mkdir -p "$SVPKG/sqlite_vec"

cp dist/vec0.so "$SVPKG/sqlite_vec/"
cp bindings/python/extra_init.py "$SVPKG/sqlite_vec/_extras.py"

cat > "$SVPKG/sqlite_vec/__init__.py" << 'EOF'
import os
_ext_path = os.path.join(os.path.dirname(__file__), "vec0.so")

def loadable_path() -> str:
    return _ext_path

def load(db):
    db.enable_load_extension(True)
    db.load_extension(_ext_path)
    db.enable_load_extension(False)

from sqlite_vec._extras import serialize_float32, serialize_int8, register_numpy
__version__ = "0.1.6"
EOF

cat > "$SVPKG/pyproject.toml" << 'EOF'
[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[project]
name = "sqlite-vec"
version = "0.1.6"
description = "sqlite-vec ppc64le build from source"
requires-python = ">=3.8"

[tool.hatch.build.targets.wheel]
packages = ["sqlite_vec"]
artifacts = ["sqlite_vec/vec0.so"]
EOF

python3.12 -m pip install "$SVPKG" --root-user-action=ignore

# ---------------------------------------------------------------------------
# 6. Build langgraph-checkpoint-sqlite
# ---------------------------------------------------------------------------

cd "$CURRENT_DIR/$PACKAGE_NAME/libs/checkpoint-sqlite"

if ! python3.12 -m pip install . --root-user-action=ignore --prefer-binary; then
    echo "------------------$PACKAGE_NAME:checkpoint_sqlite_install_fails---------------------"
    exit 1
fi

# ---------------------------------------------------------------------------
# 7. Build langgraph-checkpoint-postgres
# ---------------------------------------------------------------------------

python3.12 -m pip install "psycopg>=3.2.0" "psycopg-pool>=3.2.0" --root-user-action=ignore --prefer-binary

cd "$CURRENT_DIR/$PACKAGE_NAME/libs/checkpoint-postgres"

if ! python3.12 -m pip install . --root-user-action=ignore --prefer-binary; then
    echo "------------------$PACKAGE_NAME:checkpoint_postgres_install_fails---------------------"
    exit 1
fi

# ---------------------------------------------------------------------------
# 8. Build langgraph-prebuilt
# ---------------------------------------------------------------------------

cd "$CURRENT_DIR/$PACKAGE_NAME/libs/prebuilt"

if ! python3.12 -m pip install . --root-user-action=ignore --prefer-binary; then
    echo "------------------$PACKAGE_NAME:prebuilt_install_fails---------------------"
    exit 1
fi

# ---------------------------------------------------------------------------
# 9. Build langgraph-sdk
# ---------------------------------------------------------------------------

cd "$CURRENT_DIR/$PACKAGE_NAME/libs/sdk-py"

if ! python3.12 -m pip install . --root-user-action=ignore --prefer-binary; then
    echo "------------------$PACKAGE_NAME:sdk_install_fails---------------------"
    exit 1
fi

# ---------------------------------------------------------------------------
# 10. Build and install langgraph wheel
# ---------------------------------------------------------------------------

cd "$CURRENT_DIR/$PACKAGE_NAME/libs/langgraph"

if ! python3.12 -m build --wheel; then
    echo "------------------$PACKAGE_NAME:wheel_build_fails---------------------"
    exit 1
fi

if ! python3.12 -m pip install dist/*.whl --force-reinstall --root-user-action=ignore; then
    echo "------------------$PACKAGE_NAME:wheel_install_fails---------------------"
    exit 1
fi

# Copy wheel to current directory
cp dist/*.whl "$CURRENT_DIR"

# ---------------------------------------------------------------------------
# 11. Install SQLite
# ---------------------------------------------------------------------------

SQLITE_AUTOCONF_VER=3450300

cd "$CURRENT_DIR"

wget -q "https://www.sqlite.org/2024/sqlite-autoconf-${SQLITE_AUTOCONF_VER}.tar.gz"
tar xzf "sqlite-autoconf-${SQLITE_AUTOCONF_VER}.tar.gz"

cd "sqlite-autoconf-${SQLITE_AUTOCONF_VER}"

./configure --prefix=/usr/local --disable-static
make -j$(nproc)
make install

ldconfig
export LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH}

# ---------------------------------------------------------------------------
# 12. Install test dependencies
# ---------------------------------------------------------------------------

python3.12 -m pip install \
    pytest pytest-cov pytest-dotenv pytest-mock \
    syrupy httpx pytest-watcher "pytest-xdist[psutil]" \
    pytest-repeat pyperf pycryptodome redis \
    --root-user-action=ignore --prefer-binary

# optional dependency
python3.12 -m pip install "langgraph-cli[inmem]" --root-user-action=ignore || true

# ---------------------------------------------------------------------------
# 13. Run unit tests
# ---------------------------------------------------------------------------

cd "$CURRENT_DIR/$PACKAGE_NAME/libs/langgraph"

if ! NO_DOCKER=true python3.12 -m pytest tests/ -v; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    exit 0
fi
