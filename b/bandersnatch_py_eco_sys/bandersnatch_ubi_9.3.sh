#!/bin/bash -e
# ----------------------------------------------------------------------------
# 
# Package       : bandersnatch
# Version       : 6.5.0
# Source repo   : https://github.com/pypa/bandersnatch
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Python-eco-system
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#variables
PACKAGE_NAME="bandersnatch"
PACKAGE_VERSION=${1:-"6.5.0"}
PACKAGE_URL="ttps://github.com/pypa/bandersnatch.git"
PYTHON_VERSIONS=${2:-"3.9,3.10,3.11"}

# Update and install required packages in a single command
yum -y update && \
    yum install -y git wget sqlite sqlite-devel \ 
                libxml2-devel libxslt-devel gcc \
                gcc-c++ make cmake

#installation of rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
export PATH="$HOME/.cargo/bin:$PATH"
source ~/.bashrc
rustc --version

# Install python 3.9
yum install -y python39 python3-devel
python3.9 -m pip install --upgrade pip setuptools wheel build pytest nox tox

# Install python 3.10.14
if ! python3.10 --version; then
    cd /usr/src && \
    wget https://www.python.org/ftp/python/3.10.14/Python-3.10.14.tgz && \
    tar xzf Python-3.10.14.tgz && \
    cd Python-3.10.14 && \
    ./configure --enable-optimizations && \
    make altinstall && \
    ln -s /usr/local/bin/python3.10 /usr/bin/python3.10 && \
    ln -s /usr/local/bin/pip3.10 /usr/bin/pip3.10 && \
    cd /usr/src && \
    rm -rf Python-3.10.14.tgz Python-3.10.14

    python3.10 -m pip install --upgrade pip setuptools wheel build pytest nox tox

# Install python 3.11.9
if ! python3.11 --version; then
    cd /usr/src && \
    wget https://www.python.org/ftp/python/3.11.9/Python-3.11.9.tgz && \
    tar xzf Python-3.11.9.tgz && \
    cd Python-3.11.9 && \
    ./configure --enable-optimizations && \
    make altinstall && \
    ln -s /usr/local/bin/python3.11 /usr/bin/python3.11 && \
    ln -s /usr/local/bin/pip3.11 /usr/bin/pip3.11 && \
    cd /usr/src && \
    rm -rf Python-3.11.9.tgz Python-3.11.9

    python3.11 -m pip install --upgrade pip setuptools wheel build pytest nox tox

# Install python 3.12.5
if ! python3.12 --version; then
    cd /usr/src && \
    wget https://www.python.org/ftp/python/3.12.5/Python-3.12.5.tgz && \
    tar xzf Python-3.12.5.tgz && \
    cd Python-3.12.5 && \
    ./configure --enable-optimizations && \
    make altinstall && \
    ln -s /usr/local/bin/python3.12 /usr/bin/python3.12 && \
    ln -s /usr/local/bin/pip3.12 /usr/bin/pip3.12 && \
    cd /usr/src && \
    rm -rf Python-3.12.5.tgz Python-3.12.5
    python3.12 -m pip install --upgrade pip setuptools wheel build pytest nox tox

# Install python 3.13.0
if ! python3.13 --version; then
    cd /usr/src && \
    wget https://www.python.org/ftp/python/3.13.0/Python-3.13.0rc1.tgz && \
    tar xzf Python-3.13.0rc1.tgz && \
    cd Python-3.13.0rc1 && \
    ./configure --enable-optimizations && \
    make altinstall && \
    ln -s /usr/local/bin/python3.13 /usr/bin/python3.13 && \
    ln -s /usr/local/bin/pip3.13 /usr/bin/pip3.13 && \
    cd /usr/src && \
    rm -rf Python-3.13.0rc1.tgz Python-3.13.0rc1
    python3.13 -m pip install --upgrade pip setuptools wheel build pytest nox tox


# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

IFS=',' read -r -a python_versions <<< "$PYTHON_VERSIONS"

# Loop through each Python version
for python_version in "${python_versions[@]}"; do
    echo "Processing Package with Python $python_version"

    # Create a virtual environment directory name
    VENV_DIR="venv_$python_version"

    # Create a virtual environment
    "python$python_version" -m venv --system-site-packages "$VENV_DIR"

    # Activate the virtual environment
    source "$VENV_DIR/bin/activate"

    pip install -r requirements.txt
    pip install -r requirements_s3.txt


    # Build package
    if !(python setup.py install) ; then
        echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
        exit 1
    fi

    # Run test cases
    if !(tox -- -k "not src/bandersnatch/tests/plugins/test_storage_plugin_s3.py"); then
        echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_success_but_test_Fails"
    else
        echo "------------------$PACKAGE_NAME:build_&_test_both_success-------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Build_and_Test_Success"
    fi

    if ! python -m build --wheel --outdir=../wheels/; then
        echo "============ $PACKAGE_NAME : Wheel Creation Failed  ================="
    fi

    # Deactivate the virtual environment
    deactivate

    # Remove the virtual environment
    rm -rf "$VENV_DIR"
done