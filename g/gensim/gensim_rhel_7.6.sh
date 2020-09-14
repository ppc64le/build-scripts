# ----------------------------------------------------------------------------
#
# Package       : gensim
# Version       : 3.8.1
# Source repo   : https://github.com/RaRe-Technologies/gensim
# Tested on     : RHEL 7.6, RHEL 7.7
# Script License: Apache License, Version 2 or later
# Maintainer    : Ryan D'Mello <ryan.dmello1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

export IBM_POWERAI_LICENSE_ACCEPT=yes
export PYTHON=python3
export PYTHON_VERSION=3.6
export PIP=pip3
export LANG=en_US.utf8
export PACKAGE_VERSION=3.8.1
export PACKAGE_NAME=gensim
export PACKAGE_URL=https://github.com/RaRe-Technologies/gensim
export PATH=${PATH}:$HOME/conda/bin

yum update -y && yum install -y yum-utils
yum-config-manager repos --enable rhel-7-for-power-le-optional-rpms --enable rhel-7-server-for-power-le-rhscl-rpms
yum install -y git wget gcc gcc-c++ gcc-devel

#Install conda
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-ppc64le.sh
sh Miniconda3-latest-Linux-ppc64le.sh -u -b -p $HOME/conda
$HOME/conda/bin/conda update -y -n base conda
ln -s $HOME/conda/bin/conda /bin/conda
conda create -n ${PACKAGE_NAME} -y python=${PYTHON_VERSION}
conda init bash
eval "$(conda shell.bash hook)"
conda activate ${PACKAGE_NAME}
conda config --add channels https://public.dhe.ibm.com/ibmdl/export/pub/software/server/ibm-ai/conda/linux-ppc64le
conda install -y -c "conda-forge" libgfortran-ng==7.3.0 s3transfer==0.1.13 smart_open==1.9.0 jmespath==0.9.4 boto3==1.9.66 libopenblas==0.3.6 botocore==1.12.189 bz2file==0.98 blas==1.0 scipy==1.4.1 python-dateutil==2.8 boto==2.49.0 numpy==1.18.1  numpy-base==1.18.1 docutils==0.16	 

export TOXENV="flake8,flake8-docs"
${PYTHON} -m pip install tox 
git clone ${PACKAGE_URL} ${PACKAGE_NAME} -b ${PACKAGE_VERSION}
cd ${PACKAGE_NAME}
${PYTHON} setup.py install
tox -vv