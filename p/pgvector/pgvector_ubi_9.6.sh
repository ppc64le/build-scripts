#!/usr/bin/env bash
# -----------------------------------------------------------------------------
#
# Package	: pgvector
# Version	: v0.4.2
# Source repo	: https://github.com/pgvector/pgvector-python
# Tested on	: UBI 9.6
# Language      : python
# Ci-Check  : true
# Script License: Apache License, Version 2 or later
# Maintainer	:  Bhagyashri Gaikwad <Bhagyashri.Gaikwad2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash
set -ex

# Variables
PACKAGE_NAME=pgvector
PACKAGE_VERSION=${1:-"v0.4.2"}
PACKAGE_URL=https://github.com/pgvector/pgvector-python.git
PACKAGE_DIR=pgvector-python

# Install dependencies
yum install -y git gcc gcc-c++ gcc-gfortran make python3 python3-devel python3-pip openblas-devel

# Upgrade pip and install required tools
python3 -m pip install --upgrade pip setuptools wheel build

# Install test dependencies
# python3 -m pip install pytest pytest-cov pytest-xdist

# Install test dependencies
python3 -m pip install \
    pytest \
    pytest-cov \
    pytest-xdist \
    pytest-asyncio \
    asyncpg \
    django \
    peewee \
    pg8000 \
    psycopg \
    psycopg2-binary \
    scipy \
    sqlalchemy \
    sqlmodel
export PATH=$PATH:/usr/local/bin/

# Clone repository
git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION

# Build and install package
if ! python3 -m pip install -v .; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi

# Validate package import
if ! python3 -c "import pgvector; print('Import Successful')"; then
    echo "------------------$PACKAGE_NAME:import_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Import_Fails"
    exit 1
fi

# Run tests
# Run tests - skip database-dependent tests
if ! python3 -m pytest tests/ \
    --ignore=tests/test_asyncpg.py \
    --ignore=tests/test_django.py \
    --ignore=tests/test_peewee.py \
    --ignore=tests/test_pg8000.py \
    --ignore=tests/test_psycopg.py \
    --ignore=tests/test_psycopg2.py \
    --ignore=tests/test_sqlalchemy.py \
    --ignore=tests/test_sqlmodel.py \
    -v; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Both_Install_and_Test_Success"
    exit 0
fi
