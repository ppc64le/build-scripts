#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : onnxruntime
# Version       : v1.20.0
# Source repo   : https://github.com/microsoft/onnxruntime
# Tested on     : UBI: 9.3
# Language      : c++
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Puneet Sharma <Puneet.Sharma21@ibm.com>
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
  export PACKAGE_VERSION="v1.20.0"
else
  export PACKAGE_VERSION="$1"
fi

# install tools and dependent packages
yum install -y git gcc-c++ make wget java-11-openjdk-devel openssl-devel bzip2 zip unzip yum-utils clang clang-devel clang-libs patch cmake
export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-11)(?=.*ppc64le)')
export PATH=$JAVA_HOME/bin:$PATH

dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/
wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

#installing gcc
yum install -y gcc-toolset-12-gcc gcc-toolset-12-gcc-c++
source /opt/rh/gcc-toolset-12/enable

# Cloning the repository 
git clone $PACKAGE_URL
cd ${PACKAGE_NAME}
git checkout $PACKAGE_VERSION

# Build and test package
if !(./build.sh --allow_running_as_root --compile_no_warning_as_error --config Release) ; then
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
