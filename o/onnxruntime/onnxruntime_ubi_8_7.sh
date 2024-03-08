#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : onnxruntime
# Version       : v1.16.3
# Source repo   : https://github.com/microsoft/onnxruntime
# Tested on     : UBI: 8.7
# Language      : c++
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Stuti Wali <Stuti.Wali@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e
PACKAGE_NAME=onnxruntime
PACKAGE_URL=https://github.com/microsoft/onnxruntime

# Default tag onnxruntime
if [ -z "$1" ]; then
  export PACKAGE_VERSION="v1.16.3"
else
  export PACKAGE_VERSION="$1"
fi

# install tools and dependent packages
yum install -y git gcc-c++ make wget java-11-openjdk-devel  openssl-devel bzip2 zip unzip yum-utils clang clang-devel clang-libs
export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-11)(?=.*ppc64le)')
export PATH=$JAVA_HOME/bin:$PATH


#installing python
wget https://github.com/indygreg/python-build-standalone/releases/download/20230507/cpython-3.9.16+20230507-ppc64le-unknown-linux-gnu-install_only.tar.gz
tar -xvzf cpython-3.9.16+20230507-ppc64le-unknown-linux-gnu-install_only.tar.gz
ln -sf /python/bin/python3.9 /usr/bin/python
export PATH=/python/bin:$PATH

# miniconda, cmake installation
wget https://repo.anaconda.com/miniconda/Miniconda3-py39_4.9.2-Linux-ppc64le.sh -O miniconda.sh
bash miniconda.sh -b -p $HOME/miniconda
export PATH="$HOME/miniconda/bin:$PATH"
conda --version
python3 --version
python3 -m pip install -U pip
conda install -c conda-forge cmake=3.27.6 -y
cmake --version


#installing gcc
yum-config-manager --add-repo http://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/
yum-config-manager --add-repo http://rpmfind.net/linux/centos/8-stream/PowerTools/ppc64le/os/
yum-config-manager --add-repo http://rpmfind.net/linux/centos/8-stream/BaseOS/ppc64le/os/
wget https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official
yum install -y gcc-toolset-9-gcc gcc-toolset-9-gcc-c++
source /opt/rh/gcc-toolset-9/enable

# Cloning the repository 
git clone $PACKAGE_URL
cd ${PACKAGE_NAME}
git checkout $PACKAGE_VERSION

#if you want to build the package from non-root user then remove flag "--allow_running_as_root" from below command
#build and test stages can't be saperated as build.sh file executes build.py file internally.
# Build and test package
if !(./build.sh --allow_running_as_root --compile_no_warning_as_error) ; then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:build_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi


