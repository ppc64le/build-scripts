# ----------------------------------------------------------------------------
#
# Package       : pyclaw
# Version       : 5.4.1
# Source repo   : https://github.com/clawpack/pyclaw
# Tested on     : rhel_7.3
# Script License: Apache License, Version 2 or later
# Maintainer    : Atul Sowani <sowania@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

# Install dependencies.
sudo yum update -y
sudo yum install -y git wget libgfortran.ppc64le lapack.ppc64le bzip2 pv \
    lapack-devel.ppc64le mpich-3.0.ppc64le mpi4py-mpich.ppc64le gcc make \
    gcc-gfortran mpi4py-docs.noarch hdf5-mpich.ppc64le hdf5.ppc64le

WDIR=`pwd`

# Install miniconda and other conda packages.
wget http://repo.continuum.io/miniconda/Miniconda2-4.3.14-Linux-ppc64le.sh -O miniconda.sh
chmod +x miniconda.sh
./miniconda.sh -b -p $WDIR/miniconda
export PATH="$WDIR/miniconda/bin:$PATH"
hash -r
conda config --set always_yes yes --set changeps1 no --set show_channel_urls yes
conda update -q conda
conda install matplotlib nose coverage
pip install petsc4py spicy python-coveralls
python -c "import scipy; print(scipy.__version__)"

# Clone and build source code.
cd $WDIR
git clone https://github.com/clawpack/clawpack
cd clawpack
git submodule init
git submodule update clawutil visclaw riemann
python setup.py install
cd pyclaw/src/pyclaw
nosetests --first-pkg-wins --with-doctest --exclude=limiters \
    --exclude=sharpclaw --exclude=fileio --exclude=example --with-coverage \
    --cover-package=clawpack.pyclaw
