#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : traceloop-sdk
# Version       : v0.60.0
# Source repo   : https://github.com/traceloop/openllmetry
# Tested on     : UBI:9.6
# Language      : Python
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Varsha Kumar <varsha.kumar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Variables
REPO_DIR="openllmetry"
PACKAGE_NAME="traceloop_sdk"
PACKAGE_VERSION=${1:-v0.60.0}
PACKAGE_URL="https://github.com/traceloop/openllmetry.git"
SOURCE_ROOT="$(pwd)"

# PACKAGE_DIR must point to the actual Python package (contains pyproject.toml)
# so that the CI wheel-build harness can find it.
PACKAGE_DIR="openllmetry/packages/traceloop-sdk"

echo "Building ${PACKAGE_NAME} ${PACKAGE_VERSION}"

# Install system dependencies
# gcc-c++ is required to build grpcio from source (provides the 'c++' binary)
dnf install -y gcc gcc-c++ git python3.12 python3.12-devel python3.12-pip
# Install build frontend
python3.12 -m pip install --upgrade pip build hatchling

dnf install -y openssl-devel zlib-devel
GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=1 \
GRPC_PYTHON_BUILD_SYSTEM_ZLIB=1 \
python3.12 -m pip install "grpcio>=1.75.1" --no-binary grpcio

# Clone and checkout
rm -rf "$REPO_DIR"
git clone "$PACKAGE_URL" "$REPO_DIR"
cd "${REPO_DIR}"
git checkout "$PACKAGE_VERSION"

PACKAGES_DIR="${SOURCE_ROOT}/${REPO_DIR}/packages"
DIST_DIR="${SOURCE_ROOT}/dist"
mkdir -p "$DIST_DIR"

# Build and install all sibling instrumentation packages.
# These are declared as local path dependencies in traceloop-sdk's pyproject.toml
# and must be present before traceloop-sdk itself can be installed.
SIBLING_PACKAGES=(
    "opentelemetry-semantic-conventions-ai"
    "opentelemetry-instrumentation-agno"
    "opentelemetry-instrumentation-alephalpha"
    "opentelemetry-instrumentation-anthropic"
    "opentelemetry-instrumentation-bedrock"
    "opentelemetry-instrumentation-chromadb"
    "opentelemetry-instrumentation-cohere"
    "opentelemetry-instrumentation-crewai"
    "opentelemetry-instrumentation-google-generativeai"
    "opentelemetry-instrumentation-groq"
    "opentelemetry-instrumentation-haystack"
    "opentelemetry-instrumentation-lancedb"
    "opentelemetry-instrumentation-langchain"
    "opentelemetry-instrumentation-llamaindex"
    "opentelemetry-instrumentation-marqo"
    "opentelemetry-instrumentation-mcp"
    "opentelemetry-instrumentation-milvus"
    "opentelemetry-instrumentation-mistralai"
    "opentelemetry-instrumentation-ollama"
    "opentelemetry-instrumentation-openai"
    "opentelemetry-instrumentation-openai-agents"
    "opentelemetry-instrumentation-pinecone"
    "opentelemetry-instrumentation-qdrant"
    "opentelemetry-instrumentation-replicate"
    "opentelemetry-instrumentation-sagemaker"
    "opentelemetry-instrumentation-together"
    "opentelemetry-instrumentation-transformers"
    "opentelemetry-instrumentation-vertexai"
    "opentelemetry-instrumentation-voyageai"
    "opentelemetry-instrumentation-watsonx"
    "opentelemetry-instrumentation-weaviate"
    "opentelemetry-instrumentation-writer"
)

echo "=== Building sibling packages ==="
for pkg in "${SIBLING_PACKAGES[@]}"; do
    pkg_path="${PACKAGES_DIR}/${pkg}"
    if [ ! -d "$pkg_path" ]; then
        echo "WARNING: $pkg not found at $pkg_path, skipping"
        continue
    fi
    echo "--- Building $pkg ---"
    python3.12 -m build --wheel --outdir "$DIST_DIR" "$pkg_path"
done

echo "=== Installing sibling package wheels ==="
python3.12 -m pip install "${DIST_DIR}"/*.whl

# Build traceloop-sdk itself
echo "=== Building traceloop-sdk ==="
python3.12 -m build --wheel --outdir "$DIST_DIR" "${PACKAGES_DIR}/traceloop-sdk"

WHEEL=$(find "$DIST_DIR" -name "${PACKAGE_NAME}-*.whl" | head -1)
if [ -z "$WHEEL" ]; then
    echo "ERROR: traceloop-sdk wheel not found after build"
    exit 1
fi
echo "Wheel: $WHEEL"

cd "${SOURCE_ROOT}"

# Install traceloop-sdk wheel (sibling wheels already installed above satisfy local deps)
echo "=== Installing traceloop-sdk ==="
python3.12 -m pip install "$WHEEL"

python3.12 -m pip install httpx

# Test
echo "=== Running Tests ==="

# 1. Version check
python3.12 -c "import importlib.metadata; print('version:', importlib.metadata.version('traceloop-sdk'))"

# 2. Basic import smoke test
python3.12 - <<'EOF'
from traceloop.sdk import Traceloop
print("traceloop.sdk import: OK")

from traceloop.sdk.decorators import task, workflow, agent
print("traceloop.sdk.decorators import: OK")
EOF

echo -e "\n=== Build Complete ==="
echo "Wheel: $WHEEL"
