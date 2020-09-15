# ----------------------------------------------------------------------------
#
# Package       : hdbscan
# Version       : 0.8.24
# Source repo   : http://github.com/scikit-learn-contrib/hdbscan
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

export PYTHON=python3
export PYTHON_VERSION=3.6
export PIP=pip3
export LANG=en_US.utf8
export PACKAGE_VERSION=0.8.24
export PACKAGE_NAME=hdbscan
export PACKAGE_URL=http://github.com/scikit-learn-contrib/hdbscan

yum-config-manager repos --enable rhel-7-for-power-le-optional-rpms --enable rhel-7-server-for-power-le-rhscl-rpms

yum update -y
yum install -y python3 python3-devel python3-pip git gcc gcc-devel python3-devel blas blas-devel \
    atlas atlas-devel atlas-static lapack-devel lapack libxml2 libxml2-devel zlib-devel libxslt-devel \
	libgpg-error-devel gcc-c++ libstdc++-devel

yum clean all

${PIP} install pip==9.0.3 && ${PIP} install cython numpy req pybind wheel

# This environment variables are required for SciPy
export BLAS=/usr/lib64/libblas.so
export LAPACK=/usr/lib64/liblapack.so
export ATLAS=/usr/lib64/libsatlas.so

# In stall Scipy from source as binary not available for PPC64le
git clone https://github.com/scipy/scipy.git -b v1.2.3 && cd scipy && python3 setup.py install

${PIP} install --upgrade pip

#Install conda
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-ppc64le.sh
sh Miniconda3-latest-Linux-ppc64le.sh -u -b -p $HOME/conda
$HOME/conda/bin/conda update -y -n base conda
ln -s $HOME/conda/bin/conda /bin/conda
conda create -n ${PACKAGE_NAME} -y python=${PYTHON_VERSION}
conda init bash
eval "$(conda shell.bash hook)"
conda activate ${PACKAGE_NAME}
conda install -y pytest

git clone ${PACKAGE_URL} ${PACKAGE_NAME} -b ${PACKAGE_VERSION}
cd ${PACKAGE_NAME}
${PYTHON} setup.py install
${PYTHON} setup.py test