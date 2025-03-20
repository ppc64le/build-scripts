#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : openmpi
# Version          : 5.0.6
# Source repo      : https://download.open-mpi.org/release/open-mpi/v5.0/openmpi-5.0.6.tar.gz
# Tested on        : UBI:9.3
# Language         : Python, C, C++
# Travis-Check     : True
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
PACKAGE_VERSION=5.0.6
PACKAGE_VERSION_DIR=5.0
PACKAGE_URL=https://download.open-mpi.org/release/open-mpi/v$PACKAGE_VERSION_DIR/$PACKAGE_NAME-$PACKAGE_VERSION.tar.gz
PACKAGE_DIR=$PACKAGE_NAME-$PACKAGE_VERSION

# Install dependencies
yum install -y git g++ gcc-toolset-13 make wget openssl-devel bzip2-devel libffi-devel zlib-devel autoconf automake libtool krb5-devel cmake python3 python3-devel python3-pip

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
export CC=$GCC_HOME/bin/gcc
export CXX=$GCC_HOME/bin/g++
export CC=$(basename "$CC")
export CXX=$(basename "$CXX")
export LIBRARY_PATH="/usr/lib64"

# Enabling and installing epel-repo
yum install -y wget
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os/
wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official
dnf install --nodocs -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
yum install epel-release flex -y

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
pip install mpi4py setuptools build

#create pyproject.toml
wget https://raw.githubusercontent.com/aastha-sharma2/build-scripts/refs/heads/openmpi/o/openmpi/pyproject.toml

#install
if ! (pip install .) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

"Running the test program with mpirun..."
# Run the compiled program with mpirun
$OPENMPI_PREFIX/bin/mpirun --allow-run-as-root -n 2 ./helloworld_c
# Check if the mpirun command succeeded, if not, exit
if [ $? -ne 0 ]; then
    echo "------------------$PACKAGE_NAME:Test_Fails-------------------------------------"
    exit 1
fi
echo "OpenMPI install successful!"
