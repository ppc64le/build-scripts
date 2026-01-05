#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : openmpi
# Version          : 5.0.6
# Source repo      : https://download.open-mpi.org/release/open-mpi/v5.0/openmpi-5.0.6.tar.gz
# Tested on        : UBI:9.3
# Language         : Python, C, C++
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Aastha Sharma <aastha.sharma4@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------------------------
# Variables
PACKAGE_NAME=openmpi
PACKAGE_VERSION=${1:-5.0.6}
PACKAGE_VERSION_DIR=5.0
PACKAGE_URL=https://download.open-mpi.org/release/open-mpi/v$PACKAGE_VERSION_DIR/$PACKAGE_NAME-$PACKAGE_VERSION.tar.gz
PACKAGE_DIR=$PACKAGE_NAME-$PACKAGE_VERSION
CURRENT_DIR=$(pwd)

# Install dependencies
yum install -y git gcc-toolset-13 make wget openssl-devel bzip2-devel libffi-devel zlib-devel autoconf automake libtool krb5-devel cmake python3 python3-devel python3-pip
source /opt/rh/gcc-toolset-13/enable

echo "Downloading the tarball..."
wget $PACKAGE_URL

echo "Extracting the tarball..."
tar -xvf $PACKAGE_NAME-$PACKAGE_VERSION.tar.gz
cd $PACKAGE_NAME-$PACKAGE_VERSION

mkdir prefix
export PREFIX=$(pwd)/prefix

# Set environment variables
export GCC_HOME=/opt/rh/gcc-toolset-13/root/usr
export PATH=$GCC_HOME/bin:$PATH
export CC=$(which gcc)
export CXX=$(which g++)
export CC=$(basename "$CC")
export CXX=$(basename "$CXX")
export LIBRARY_PATH="/usr/lib64"

# Configure to set the installation prefix and disable dependency tracking
./configure --prefix=$PREFIX --disable-dependency-tracking
# Make to build Open MPI with parallel processing
make -j 4
# Install Open MPI to the specified prefix directory
make install

# Create the necessary directory structure and copy OpenMPI files
mkdir -p local/openmpi
cp -r $PREFIX/* local/openmpi/

# Set path for mpi/ompi
export PATH=$PREFIX/bin:$PATH
export LD_LIBRARY_PATH=$PREFIX/lib:$LD_LIBRARY_PATH

# Install Python bindings
pip install setuptools build

#create pyproject.toml
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/o/openmpi/pyproject.toml
sed -i s/{PACKAGE_VERSION}/$PACKAGE_VERSION/g pyproject.toml

#get testfile
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/o/openmpi/helloworld.c

echo "Running the test program with mpirun..."
$PREFIX/bin/mpicc helloworld.c -o helloworld_c 
$PREFIX/bin/mpirun --allow-run-as-root -n 2 ./helloworld_c 

# Handle test failure
if [ $? -ne 0 ]; then
    echo "------------------$PACKAGE_NAME:Test_Fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Test_Fails"
    exit 1
fi

#install
if ! (pip install .) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi
#build wheel
if ! (python3 -m build --wheel --outdir="$CURRENT_DIR") ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi
