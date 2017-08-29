# ----------------------------------------------------------------------------
#
# Package	: clawpack
# Version	: 5.4.1
# Source repo	: https://github.com/clawpack/clawpack
# Tested on	: ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer	: Snehlata Mohite <smohite@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

# Update source
sudo apt-get update -y
sudo apt-get install -y build-essential python python-setuptools python-dev \
  libopenmpi-dev python-lxml python-pip pkg-config libhdf5-dev \
  libpetsc3.6.2-dev petsc-dev liblapack-pic pv liblapack-dev libsqlite3-0 \
  libfontconfig1 libfreetype6-dev libssl1.0.0 libpng12-0 libjpeg62 libx11-6 \
  libxext6 gcc gfortran git
sudo pip install --upgrade pip --upgrade setuptools
sudo pip install ez_setup numpy scipy==0.17.1 six nose h5py==2.6.0 \
  pytest petsc petsc4py mpi4py functools32 subprocess32 pytz cycler \
  tornado pyparsing

# Clone source code.
git clone https://github.com/clawpack/clawpack.git
cd clawpack
export PYTHONPATH=/usr/lib/python2.7
export PYTHONPATH=${PWD}:$PYTHONPATH
export CLAW=${PWD}

# Build and Install.
python setup.py git-dev
sudo pip install -e .
nosetests -sv --1st-pkg-wins --exclude=pyclaw
