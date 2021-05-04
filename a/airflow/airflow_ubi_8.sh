# ----------------------------------------------------------------------------
#
# Package       : Airflow
# Version       : 2.0.1
# Source repo   : https://github.com/apache/airflow
# Tested on     : UBI 8
# Script License: Apache License Version 2.0
# Maintainer    : Swati Singhal <swati.singhal@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

CWD=`pwd`
export PATH=${PATH}:$HOME/conda/bin
export PATH=${PATH}:/root/conda/envs/airflow/bin
export PYTHONPATH=${PYTHONPATH}:/root/conda/envs/airflow/lib/python3.8/site-packages
export PYTHON_VERSION=3.8
export AIRFLOW_HOME=~/airflow

export LIBRARY_PATH=$LIBRARY_PATH:/usr/local/opt/openssl/lib/
export CRYPTOGRAPHY_DONT_BUILD_RUST=1
export PYTHON=/usr/local/bin/python3.8

#Core test case essentials
export AIRFLOW__CELERY_BROKER_TRANSPORT_OPTIONS__VISIBILITY_TIMEOUT=21600
export AIRFLOW__CELERY_BROKER_TRANSPORT_OPTIONS___TEST_ONLY_BOOL=true
export AIRFLOW__CELERY_BROKER_TRANSPORT_OPTIONS___TEST_ONLY_FLOAT=1.6
export AIRFLOW__CELERY_BROKER_TRANSPORT_OPTIONS___TEST_ONLY_STRING=this is a test

##Installations were not successful through rhn repositories hence used centos and epel
dnf -y --disableplugin=subscription-manager install http://mirror.centos.org/centos/8/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8-2.el8.noarch.rpm http://mirror.centos.org/centos/8/BaseOS/ppc64le/os/Packages/centos-linux-repos-8-2.el8.noarch.rpm https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
yum update -y
yum install -y git wget curl make gcc-c++ procps cmake
yum install -y sqlite-devel mysql-devel libpq-devel-12.5-1.el8_3.ppc64le leveldb-devel unixODBC-devel python38-devel.ppc64le openldap-devel.ppc64le freetds-devel.ppc64le openssl-devel bzip2-devel libffi-devel zlib-devel
##Airflow required pip versipn 20.2.4 as of now
pip install --upgrade pip==20.2.4

cd $CWD
##Install conda
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-ppc64le.sh
sh Miniconda3-latest-Linux-ppc64le.sh -u -b -p $HOME/conda
$HOME/conda/bin/conda update -y -n base conda
conda create -n airflow -y python=3.8
conda init bash
eval "$(conda shell.bash hook)"
conda activate airflow
conda install -y pytest

git clone https://github.com/apache/airflow
cd airflow
git checkout 2.0.1
wget https://raw.githubusercontent.com/apache/airflow/constraints-2.0.1/constraints-3.8.txt

## install as much as possible through conda
while read requirement; do conda install -c conda-forge --yes $requirement; done < constraints-3.8.txt
read -p "Conda installation done. Attempting rest through pip"


## remaining installations through pip, issue in below packages
## hence try installing them first
pip install snowflake-connector-python
pip install snowflake-sqlalchemy==1.2.4


##browse through constraint file and install whatever remains
while read requirement; do pip install $requirement; done < constraints-3.8.txt


##Install Airflow
python setup.py install
read -p "initializing db"
airflow db init

##input password xyz
airflow users create \
    --username admin \
    --firstname Peter \
    --lastname Parker \
    --role Admin \
    --email spiderman@superhero.org


##all test cases
python3 setup.py test > test_log.txt

##individual test cases
python -m pytest tests/always > always_result.txt
python -m pytest tests/api > api_result.txt
python -m pytest tests/api_connexion > api_connexion_result.txt
python -m pytest tests/bats > bats_result.txt
python -m pytest tests/cli > cli_result.txt
python -m pytest tests/cluster_policies > cp_result.txt
python -m pytest tests/core > core_result.txt
python -m pytest tests/dags > dags_result.txt
python -m pytest tests/dags_corrupted > dags_corrupted_result.txt
python -m pytest tests/dags_with_system_exit > dags_with_system_exit_result.txt
python -m pytest tests/executors > executors_result.txt
python -m pytest tests/hooks > hooks_result.txt
python -m pytest tests/jobs > jobs_result.txt
python -m pytest tests/kubernetes > kubernetes_result.txt
python -m pytest tests/lineage > lineage_result.txt
python -m pytest tests/macros > macros_result.txt
python -m pytest tests/models > models_result.txt
python -m pytest tests/operators > operators_result.txt
python -m pytest tests/plugins > plugins_result.txt
python -m pytest tests/providers > providers_result.txt
python -m pytest tests/secrets > secrets_result.txt
python -m pytest tests/security > security_result.txt
python -m pytest tests/sensors > sensors_result.txt
python -m pytest tests/serialization > serialization_result.txt
python -m pytest tests/task > task_result.txt
python -m pytest tests/test_utils > test_utils_result.txt
python -m pytest tests/testconfig/conf > testconfig_conf_result.txt
python -m pytest tests/ti_deps > ti_deps_result.txt
python -m pytest tests/utils > utils_result.txt
python -m pytest tests/www > www_result.txt


