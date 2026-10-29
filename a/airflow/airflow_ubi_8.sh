#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : airflow
# Version       : 2.0.1
# Source repo   : https://github.com/apache/airflow
# Tested on     : UBI 8
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Swati Singhal <swati.singhal@ibm.com>
# -----------------------------------------------------------------------------
# WARNING: Auto-migrated script - REVIEW REQUIRED
#   - Original: airflow_ubi_8.sh
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="airflow"
PACKAGE_VERSION="${1:-2.0.1}"
PACKAGE_URL="https://github.com/apache/airflow"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="bzip2-devel cmake curl freetds-devel.ppc64le gcc-c++ git leveldb-devel libffi-devel libpq-devel-12.5-1.el8_3.ppc64le make mysql-devel openldap-devel.ppc64le openssl-devel procps python38-devel.ppc64le sqlite-devel unixODBC-devel wget zlib-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# OPTIONAL: Custom environment variables (from original script)
# =============================================================================
export PYTHONPATH=${PYTHONPATH}:/root/conda/envs/airflow/lib/python3.8/site-packages
export PYTHON_VERSION=3.8
export AIRFLOW_HOME=~/airflow
export LIBRARY_PATH=$LIBRARY_PATH:/usr/local/opt/openssl/lib/
export CRYPTOGRAPHY_DONT_BUILD_RUST=1
export PYTHON=/usr/local/bin/python3.8
export AIRFLOW__CELERY_BROKER_TRANSPORT_OPTIONS__VISIBILITY_TIMEOUT=21600
export AIRFLOW__CELERY_BROKER_TRANSPORT_OPTIONS___TEST_ONLY_BOOL=true
export AIRFLOW__CELERY_BROKER_TRANSPORT_OPTIONS___TEST_ONLY_FLOAT=1.6
export AIRFLOW__CELERY_BROKER_TRANSPORT_OPTIONS___TEST_ONLY_STRING=this is a test

# REVIEW - following code was not auto-migrated. See PORTING-NOTES.md for details.
# echo "Usage: $0 [-v <PACKAGE_VERSION>]"
# echo "       PACKAGE_VERSION is an optional paramater whose default value is 2.0.1"
# export PATH=${PATH}:$HOME/conda/bin
# export PATH=${PATH}:/root/conda/envs/airflow/bin
# export PYTHONPATH=${PYTHONPATH}:/root/conda/envs/airflow/lib/python3.8/site-packages
# export PYTHON_VERSION=3.8
# export AIRFLOW_HOME=~/airflow
# export LIBRARY_PATH=$LIBRARY_PATH:/usr/local/opt/openssl/lib/
# export CRYPTOGRAPHY_DONT_BUILD_RUST=1
# export PYTHON=/usr/local/bin/python3.8
# export AIRFLOW__CELERY_BROKER_TRANSPORT_OPTIONS__VISIBILITY_TIMEOUT=21600
# export AIRFLOW__CELERY_BROKER_TRANSPORT_OPTIONS___TEST_ONLY_BOOL=true
# export AIRFLOW__CELERY_BROKER_TRANSPORT_OPTIONS___TEST_ONLY_FLOAT=1.6
# export AIRFLOW__CELERY_BROKER_TRANSPORT_OPTIONS___TEST_ONLY_STRING=this is a test
# pip install --upgrade pip==20.2.4
# wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-ppc64le.sh
# sh Miniconda3-latest-Linux-ppc64le.sh -u -b -p $HOME/conda
# $HOME/conda/bin/conda update -y -n base conda
# conda create -n airflow -y python=3.8
# conda init bash
# eval "$(conda shell.bash hook)"
# conda activate airflow
# conda install -y pytest
# git clone https://github.com/apache/airflow
# cd airflow
# wget https://raw.githubusercontent.com/apache/airflow/constraints-$PACKAGE_VERSION/constraints-3.8.txt
# while read requirement; do conda install -c conda-forge --yes $requirement; done < constraints-3.8.txt
# read -p "Conda installation done. Attempting rest through pip"
# pip install snowflake-connector-python
# pip install snowflake-sqlalchemy==1.2.4
# while read requirement; do pip install $requirement; done < constraints-3.8.txt
# python setup.py install
# read -p "initializing db"
# airflow db init
# airflow users create \
#     --username admin \
#     --firstname Peter \
#     --lastname Parker \
#     --role Admin \
#     --email spiderman@superhero.org
# python3 setup.py test > test_log.txt

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
