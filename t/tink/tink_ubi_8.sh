# ----------------------------------------------------------------------------
#
# Package         : tink
# Version         : v1.6.1 
# Source repo     : https://github.com/google/tink
# Tested on       : RHEL 8.3
# Script License  : Apache License, Version 2.0
# Maintainer      : Raju Sah <Raju.Sah@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#! /bin/bash

yum update -y
#install prerequisite depencdency
yum install -y gcc gcc-c++ wget patch \
    make python36 zip unzip git \
    java-11-openjdk-devel.ppc64le \
        java-1.8.0-openjdk-devel.ppc64le

#do soft link.
ln -s /usr/bin/python3 /usr/bin/python

#download bazel source and build it.
wget https://github.com/bazelbuild/bazel/releases/download/4.1.0/bazel-4.1.0-dist.zip
mkdir -p  bazel-4.1.0
unzip bazel-4.1.0-dist.zip -d bazel-4.1.0/
cd bazel-4.1.0/
export EXTRA_BAZEL_ARGS="--host_javabase=@local_jdk//:jdk" bash
./compile.sh
#export the path of bazel bin
export PATH=/bazel-4.1.0/output/:$PATH

cd ../

#clone the git repo.
git clone https://github.com/google/tink
cd tink/
git checkout v1.6.1

#build the repo.
 bazel build //:tink_version
 
#Run the test
cd testing/java_src/
bazel test ...
cd ../cc/
bazel test ...
cd ../go/
bazel test ...
