# -----------------------------------------------------------------------------
#
# Package	: protobuf
# Version	: v21.5
# Source repo	: https://github.com/protocolbuffers/protobuf
# Tested on	: UBI 8.5
# Language      : Java,C++
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Muskaan Sheik <Muskaan.Sheik@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=protobuf
PACKAGE_VERSION=${1:-v21.5}
PACKAGE_URL=https://github.com/protocolbuffers/protobuf.git

yum install -y sudo
sudo yum update -y
sudo yum install -y gcc-c++ wget git

dnf install -y dnf-plugins-core
dnf copr enable vbatts/bazel -y
dnf install -y bazel4

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init --recursive
bazel build :protoc :protobuf
cp bazel-bin/protoc /usr/local/bin