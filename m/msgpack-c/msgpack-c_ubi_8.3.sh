# ----------------------------------------------------------------------------
#
# Package       : msgpack-c
# Version       : 3.2.1                                                                                                               
# Source repo   : https://github.com/msgpack/msgpack-c 
# Tested on     : UBI 8.3
# Script License: Apache License, Version 2 or later
# Maintainer	: Siddhesh Ghadi <Siddhesh.Ghadi@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash
set -ex 

dnf update -y

#adding extra repo 
dnf -y --disableplugin=subscription-manager install \
    http://mirror.centos.org/centos/8/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8-2.el8.noarch.rpm \
    http://mirror.centos.org/centos/8/BaseOS/ppc64le/os/Packages/centos-linux-repos-8-2.el8.noarch.rpm \
    https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm

#installing dependency 
dnf install gcc gcc-c++ make cmake libtool git -y
dnf install zlib-devel python3 flex bison wget unzip  -y 

alternatives --set python /usr/bin/python3 

#setting default variables
VERSION=${1:-'cpp-3.2.1'}
GTEST_VERSION=${GTEST_VERSION:-'1.7.0'}
DOXYGEN_VERSION=${DOXYGEN_VERSION:-'Release_1_9_2'}

# getting sources 
cd ~
git clone https://github.com/msgpack/msgpack-c --branch $VERSION                                                                                                               
wget https://github.com/google/googletest/archive/release-${GTEST_VERSION}.zip -O googletest-release-${GTEST_VERSION}.zip
unzip googletest-release-${GTEST_VERSION}.zip
git clone https://github.com/doxygen/doxygen --branch ${DOXYGEN_VERSION} 

#building doxygen from source 
cd ~/doxygen                                                                                                              
cmake .
make 
make install 

# building gTest from source 
cd ~/googletest-release-${GTEST_VERSION}                                                                                             
cmake .
make 
cp -r include/gtest /usr/include
cp *.a /usr/lib

#building and testing msgpack-c 
cd ~/msgpack-c                                                                                                               
cmake .
make 
make install 
make test 

#uncomment these lines to disable extra repos 
#dnf config-manager --set-disabled appstream
#dnf config-manager --set-disabled baseos                                              
#dnf config-manager --set-disabled extras                                              
#dnf config-manager --set-disabled epel                                      
#dnf config-manager --set-disabled epel-modular 