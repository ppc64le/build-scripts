#!/bin/bash -e
# ----------------------------------------------------------------------------
# 
# Package       : async_generator
# Version       : 1.1
# Source repo   : https://github.com/python-trio/async_generator.git
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
PACKAGE_NAME="async_generator"
PACKAGE_VERSION=${1:-"1.1"}
PACKAGE_URL="https://github.com/python-trio/async_generator.git"
PYTHON_VERSIONS=${2:-"3.9,3.10,3.11"}

# Update and install required packages in a single command
yum -y update && \
    yum install -y --skip-broken sudo \
                   wget \
                   python39 python3-devel\
                   ncurses git gcc gcc-c++ \
                   libffi libffi-devel \
                   sqlite sqlite-devel sqlite-libs \
                   make cmake cargo openssl-devel

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

    sh build_whl.sh $PACKAGE_NAME $PACKAGE_VERSION $PACKAGE_URL

    # Deactivate the virtual environment
    deactivate

    # Remove the virtual environment
    rm -rf "$VENV_DIR"
done