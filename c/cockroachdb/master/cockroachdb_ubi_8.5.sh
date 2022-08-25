#!/bin/bash -ex
# ----------------------------------------------------------------------------
# Package        : cockroach
# Version        : master
# Source repo    : https://github.com/cockroachdb/cockroach
# Tested on      : UBI 8.5
# Language       : GO
# Travis-Check   : False
# Script License : Apache License, Version 2 or later
# Maintainer     : Prashant Khoje <prashant.khoje@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# Automated build is disabled as it takes > 50 min to build the package.
# ----------------------------------------------------------------------------
export GO_DISTRO=linux-ppc64le
export GO_VERSION=1.18.4

# Install all dependencies
dnf install -y git cmake make gcc-c++ autoconf ncurses-devel libarchive curl \
    wget openssl-devel diffutils procps-ng libarchive xz python2 patch

dnf install -y \
    http://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/bison-3.0.4-10.el8.ppc64le.rpm \
    http://rpmfind.net/linux/epel/8/Everything/ppc64le/Packages/c/ccache-3.7.7-1.el8.ppc64le.rpm

# Install nodejs
dnf module install -y nodejs:14

# Install and setup go environment
export GOPATH=$HOME/go
curl -O https://dl.google.com/go/go$GO_VERSION.$GO_DISTRO.tar.gz
tar -C /usr/local -xzf go$GO_VERSION.$GO_DISTRO.tar.gz
rm -rf go$GO_VERSION.$GO_DISTRO.tar.gz

# Install bazel
dnf copr enable vbatts/bazel -y
dnf install -y bazel5

# Create a non-root user
NON_ROOT_USER="user"
useradd --create-home --home-dir /home/$NON_ROOT_USER --shell /bin/bash $NON_ROOT_USER

echo '#!/bin/bash -ex
export GOPATH=$HOME/go
export PATH=$PATH:/usr/local/go/bin

cd $HOME

COCKROACH_HOME=$GOPATH/src/github.com/cockroachdb
mkdir -p $COCKROACH_HOME

# Clone cockroachdb source
COCKROACH_VERSION=master
cd $COCKROACH_HOME
git clone --recursive https://github.com/cockroachdb/cockroach.git
cd cockroach
git checkout $COCKROACH_VERSION

# Apply patch for bazel based build
$HOME/bazel-build-patch-edit.sh

# Apply patch for TextExecBuild failures (https://github.com/golang/geo/pull/91)
cd vendor
git apply $HOME/01-vendor-golang-geo-s2-latlng.patch

# Build cockroachdb oss target
cd $COCKROACH_HOME/cockroach
bazel build pkg/cmd/cockroach-oss --verbose_failures

# Run tests - disabled at present
# cd $COCKROACH_HOME/cockroach
# bazel test //pkg:all_tests --test_env=GOTRACEBACK=all --test_output errors --test_timeout=45 --keep_going=true' > build_as_non_root_user.sh

SCRIPT=$(readlink -f $0)
SCRIPT_DIR=$(dirname $SCRIPT)
cp build_as_non_root_user.sh /home/$NON_ROOT_USER/
cp $SCRIPT_DIR/01-vendor-golang-geo-s2-latlng.patch /home/$NON_ROOT_USER/
cp $SCRIPT_DIR/bazel-build-patch-edit.txt /home/$NON_ROOT_USER/bazel-build-patch-edit.sh

chown $NON_ROOT_USER:$NON_ROOT_USER /home/$NON_ROOT_USER/*.*
chmod +x /home/$NON_ROOT_USER/*.sh

su -c /home/$NON_ROOT_USER/build_as_non_root_user.sh $NON_ROOT_USER
