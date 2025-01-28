#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : jax
# Version          : jax-v0.4.7
# Source repo      : https://github.com/jax-ml/jax      
# Tested on	   : UBI:9.3 
# Language         : Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : vinodk99 <Vinod.K1@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=jax
PACKAGE_VERSION=${1:-jax-v0.4.7}
PACKAGE_URL=https://github.com/jax-ml/jax 


OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

yum install -y gcc gcc-c++ make libtool cmake git wget xz zlib-devel openssl-devel bzip2-devel libffi-devel libevent-devel unzip clang python python-devel 
yum install -y git make wget gcc-c++ java-11-openjdk java-11-openjdk-devel java-11-openjdk-headless zip  gcc-gfortran openblas openblas-devel

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH=$PATH:$JAVA_HOME/bin

#Install bazel
wget https://github.com/bazelbuild/bazel/releases/download/6.5.0/bazel-6.5.0-dist.zip
mkdir -p  bazel-6.5.0
unzip bazel-6.5.0-dist.zip -d bazel-6.5.0/
cd bazel-6.5.0/
export EXTRA_BAZEL_ARGS="--host_javabase=@local_jdk//:jdk" bash
./compile.sh
#export the path of bazel bin
export PATH=/bazel-6.5.0/output/:$PATH
cd /

pip install numpy==1.26.4 scipy opt-einsum==3.3.0  ml-dtypes==0.5.0 absl-py wheel


git clone $PACKAGE_URL 
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! python setup.py install ; then
        echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
fi

if ! python setup.py bdist_wheel ; then
        echo "------------------$PACKAGE_NAME:wheel_built_fails---------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  wheel_built_fails"
	exit 2
else
        echo "------------------$PACKAGE_NAME:wheel_built_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Wheel_built_success"
	exit 0
fi

#skipping tests as it requires tensorflow dependency.