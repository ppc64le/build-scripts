#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package          : OpenSearch Build
# Version          : 3.6.0
# Source repo      : https://github.com/opensearch-project/opensearch-build.git
# Tested on        : UBI 10.2
# Language         : Java, Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Jason Cho<jason.cho2@ibm.com>
#
# Disclaimer       : This script has been tested in non-root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------
set -e

PACKAGE_NAME=opensearch-build
PACKAGE_URL=https://github.com/opensearch-project/opensearch-build.git
PACKAGE_VERSION=${1:-3.6.0}
SCRIPT=$(readlink -f $0)
SCRIPT_DIR=$(dirname $SCRIPT)

# Install system packages
dnf install -y git podman-docker java-25-openjdk-devel wget openssl-devel zlib-devel python3-pip make gcc gcc-c++

# Install Python 3.9 if needed
if [ -x /usr/local/bin/python3.9 ] && /usr/local/bin/python3.9 -c "import ssl" >/dev/null 2>&1; then
    echo "Python 3.9 with SSL already installed, skipping build"
else
    echo "Installing Python 3.9.21..."
    wget https://www.python.org/ftp/python/3.9.21/Python-3.9.21.tgz
    tar -xvzf Python-3.9.21.tgz -C /tmp
    cd /tmp/Python-3.9.21
    make clean || true
    ./configure --enable-optimizations --prefix=/usr/local --with-openssl=/usr
    make -j$(nproc)
    make altinstall

    # Install pip for Python 3.9
    curl -sSL https://bootstrap.pypa.io/pip/3.9/get-pip.py -o /tmp/get-pip.py
    /usr/local/bin/python3.9 /tmp/get-pip.py
    rm /tmp/get-pip.py

    # Fix permissions so non-root users can use pip
    chmod -R 755 /usr/local/lib/python3.9/site-packages/

    # Clean up Python build artifacts
    cd $SCRIPT_DIR
    rm -f Python-3.9.21.tgz
    rm -rf /tmp/Python-3.9.21
fi

# Remove any existing system pipenv to avoid conflicts
pip uninstall pipenv -y 2>/dev/null || true
pip3 uninstall pipenv -y 2>/dev/null || true
python3 -m pip uninstall pipenv -y 2>/dev/null || true
rm -rf /usr/local/lib/python3.*/site-packages/pipenv* 2>/dev/null || true
rm -f /usr/local/bin/pipenv 2>/dev/null || true

# Install pipenv for Python 3.9
/usr/local/bin/python3.9 -m pip install pipenv
ln -sf /usr/local/bin/python3.9 /usr/local/bin/python3
ln -sf /usr/local/bin/python3.9 /usr/bin/python3
# Set Java environment variables and ensure all tools are in PATH
export JAVA_HOME=/usr/lib/jvm/java-25-openjdk
export PATH="/usr/local/bin:$HOME/.local/bin:$JAVA_HOME/bin:$PATH"
export PIPENV_PYTHON=/usr/local/bin/python3.9

# Install yq
wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_ppc64le
chmod 755 /usr/local/bin/yq

# Set up build directory
BUILD_DIR=${BUILD_DIR:-$(pwd)/opensearch-workspace}
mkdir -p $BUILD_DIR
cd $BUILD_DIR

# Clean up any existing directory
rm -rf $PACKAGE_NAME

# Clone and build
git clone $PACKAGE_URL
cd $PACKAGE_NAME

git apply $SCRIPT_DIR/${PACKAGE_NAME}_${PACKAGE_VERSION}.patch

./build.sh manifests/$PACKAGE_VERSION/opensearch-$PACKAGE_VERSION.yml --platform linux --architecture ppc64le --distribution tar --continue-on-error

./assemble.sh tar/builds/opensearch/manifest.yml

TARBALL=$(find $BUILD_DIR/opensearch-build/tar/dist/opensearch -name "*.tar.gz" | head -1)
cp "$TARBALL" /build/opensearch-ppc64le.tgz
DOCKER_RELEASE_DIR=$BUILD_DIR/opensearch-build/docker/release
cp /build/opensearch-ppc64le.tgz $DOCKER_RELEASE_DIR/
cp $SCRIPT_DIR/Dockerfile $DOCKER_RELEASE_DIR/dockerfiles/
echo "Build complete, now build image using command"
echo "cd opensearch-workspace/opensearch-build/docker/release"
echo "./build-image-single-arch.sh -v 3.6.0 -f dockerfiles/Dockerfile -p opensearch -a ppc64le -t $(pwd)/opensearch-ppc64le.tgz"
