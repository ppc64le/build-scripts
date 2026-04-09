#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package          : gradio
# Version          : gradio@06.9.0
# Source repo      : https://github.com/gradio-app/gradio.git
# Tested on        : UBI 9.7
# Language         : Python, Svelte, TypeScript
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Prachi Gaonkar <Prachi.Gaonkar@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

PACKAGE_NAME="gradio"
PACKAGE_VERSION=${1:-gradio@6.9.0}
PACKAGE_URL="https://github.com/gradio-app/gradio.git"
NODE_VERSION=${NODE_VERSION:-24}
BUILD_HOME="$(pwd)"

echo "Building ${PACKAGE_NAME} version ${PACKAGE_VERSION}"

# -------------------------------------------------------
# Install system dependencies
# -------------------------------------------------------
echo "Installing build dependencies..."

yum install -y \
  git \
  gcc gcc-c++ make \
  python3.12 \
  python3.12-devel \
  python3.12-pip \
  which \
  tar \
  zlib-devel \
  libpng-devel \
  freetype-devel \
  libjpeg-turbo \
  libjpeg-turbo-devel

echo "Installing Node.js and pnpm..."
#Installing nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source "$HOME"/.bashrc
echo "installing nodejs $NODE_VERSION"
nvm install "$NODE_VERSION" >/dev/null
nvm use $NODE_VERSION

npm install -g pnpm

# -------------------------------------------------------
# Install Pillow (from source)
# -------------------------------------------------------
echo "Installing Pillow..."

cd "${BUILD_HOME}"
git clone https://github.com/python-pillow/Pillow
cd Pillow
git checkout 11.1.0
git submodule update --init

python3.12 -m pip install .

# -------------------------------------------------------
# Clone Gradio repository
# -------------------------------------------------------
echo "Cloning ${PACKAGE_NAME} repository..."

cd "${BUILD_HOME}"
git clone "${PACKAGE_URL}"
cd "${PACKAGE_NAME}" && git checkout "${PACKAGE_VERSION}"

# -------------------------------------------------------
# Install dependencies
# -------------------------------------------------------
echo "Installing dependencies..."

pnpm install
pip3.12 install -r requirements.txt

# Increase Node memory for large builds
export NODE_OPTIONS="--max-old-space-size=8192"

# -------------------------------------------------------
# Generate theme assets (pre-build step)
# -------------------------------------------------------
echo "Generating @gradio/theme assets..."

if ! pnpm --filter @gradio/theme generate; then
  echo "------------------ ${PACKAGE_NAME}: Theme Generation Failed ------------------"
  exit 1
fi

# -------------------------------------------------------
# Workspace build
# -------------------------------------------------------
echo "Running workspace build..."

if ! pnpm -r \
  --filter '!./js/build' \
  --filter '!./js/component-test' \
  --filter '!./js/_spaces-test' \
  --filter '!./js/_website' \
  build; then
  echo "------------------ ${PACKAGE_NAME}: Workspace Build Failed ------------------"
  exit 1
fi

# -------------------------------------------------------
#  Install the Python package
# -------------------------------------------------------
echo "Installing Gradio Python package..."

if ! pip3.12 install .; then
  echo "------------------ ${PACKAGE_NAME}: Python Install Failed ------------------"
  exit 1
fi

# -------------------------------------------------------
# Run unit tests
# -------------------------------------------------------
echo "Running unit tests..."

if ! pnpm test:run; then
  echo "------------------ ${PACKAGE_NAME}: Unit Tests Failed ------------------"
  exit 2
fi

# -------------------------------------------------------
# Skip browser tests (ppc64le limitation)
# -------------------------------------------------------
echo "Skipping browser tests (unsupported on ppc64le)"
#if ! pnpm test:browser:full; then 
# echo "------------------ ${PACKAGE_NAME}: Browser Tests Failed ------------------" 
# exit 2 
#fi



# -------------------------------------------------------
# Success message
# -------------------------------------------------------
GRADIO_BIN=$(which gradio || true)

echo "--------------------------------------------------"
echo " ${PACKAGE_NAME} ${PACKAGE_VERSION} Build and Unit Tests Successful"
if [ -n "$GRADIO_BIN" ]; then
  echo "Gradio CLI installed at: ${GRADIO_BIN}"
else
  echo "Gradio CLI binary not found in PATH"
fi
echo "--------------------------------------------------"
