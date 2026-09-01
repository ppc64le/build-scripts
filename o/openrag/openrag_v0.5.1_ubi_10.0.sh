#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : openrag
# Version       : 0.5.1
# Source repo   : https://github.com/afsanjar/openrag
# Tested on     : UBI:10.0
# Language      : Python
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Kamryn Schock kamrynschock@ibm.com
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

set -ex

PACKAGE_NAME=openrag
PACKAGE_VERSION=${1:-0.5.1}
PACKAGE_URL=https://github.com/afsanjar/openrag
PACKAGE_BRANCH=ppc64le-0.5.1
PACKAGE_DIR=openrag
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

# -----------------------------------------------------------------------------
# System dependencies
# -----------------------------------------------------------------------------
dnf install -y \
    git curl wget \
    gcc gcc-c++ make \
    openblas-devel \
    && dnf clean all

# Install uv (required by openrag's build system)
# uv manages its own Python 3.13 download — no system python3.13 package needed
curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="$HOME/.local/bin:$PATH"

# Fetch Python 3.13 via uv (downloads a standalone ppc64le build)
uv python install 3.13

# -----------------------------------------------------------------------------
# Clone
# -----------------------------------------------------------------------------
if ! git clone --branch "$PACKAGE_BRANCH" --depth 1 "$PACKAGE_URL" "$PACKAGE_DIR"; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Clone_Fails"
    exit 1
fi

cd "$PACKAGE_DIR"

# -----------------------------------------------------------------------------
# Configure ppc64le-compatible index and build the wheel
# -----------------------------------------------------------------------------
export UV_EXTRA_INDEX_URL="https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/"
export UV_INDEX_STRATEGY="unsafe-best-match"

# Remove lock file so uv resolves fresh against the ppc64le index
rm -f uv.lock

if ! uv build --python 3.13; then
    echo "------------------$PACKAGE_NAME:build_fails---------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Build_Fails"
    exit 1
fi

# -----------------------------------------------------------------------------
# Install the built wheel into a venv and verify
# -----------------------------------------------------------------------------
WHEEL=$(ls dist/${PACKAGE_NAME}-*.whl | head -1)

uv venv --python 3.13 /tmp/openrag-venv

if ! uv pip install --python /tmp/openrag-venv \
        --extra-index-url "https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/" \
        --index-strategy unsafe-best-match \
        "$WHEEL"; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi

# The wheel installs modules at the top level (tui/, utils/, api/, etc.) rather
# than under an 'openrag' namespace — verify the installed entry point module loads.
if ! /tmp/openrag-venv/bin/python -c "import tui.main"; then
    echo "------------------$PACKAGE_NAME:import_fails--------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Import_Fails"
    exit 2
fi

echo "------------------$PACKAGE_NAME:build_and_install_success----------"
echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Build_and_Install_Success"
exit 0
