# ----------------------------------------------------------------------------
#
# Package			:	Swift
# Version			:	5.1
# Source repo		:	https://github.com/apple/swift.git
# Tested on			:	ubuntu_16.04
# Script License	:	Apache License, Version 2 or later
# Maintainer		:	Sarvesh Tamba <sarvesh.tamba@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

#Install dependencies
sudo apt-get update -y
sudo apt-get install -y git cmake ninja-build clang python uuid-dev libicu-dev \
	icu-devtools libbsd-dev libedit-dev libxml2-dev libsqlite3-dev swig \
	libpython-dev libncurses5-dev pkg-config libblocksruntime-dev libcurl4-openssl-dev \
	systemtap-sdt-dev tzdata rsync openssh-server libc++-dev libc++abi-dev ocaml \
	autoconf libtool ca-certificates libstdc++-5-dev libobjc-5-dev sphinx-common \
	build-essential g++ re2c libc++1 libc++abi1 libc++-helpers libc++-test \
	libc++abi-test binutils libncurses-dev python-dev sqlite3 python-pexpect gdb

#Set required environment variables
WDIR=`pwd`
SWIFT_BUILD_DIR=$WDIR/swift-source/build/buildbot_linux
export PYTHONPATH="$SWIFT_BUILD_DIR/lldb-linux-powerpc64le/lib/python2.7/site-packages"
export LD_LIBRARY_PATH="$SWIFT_BUILD_DIR/swift-linux-powerpc64le/lib/swift/linux/:$SWIFT_BUILD_DIR/swift-linux-powerpc64le/lib/swift/linux/powerpc64le/:$LD_LIBRARY_PATH"

#Clone swift-5.1-branch and build the toolchain.
mkdir swift-source
cd swift-source
git clone https://github.com/apple/swift.git
./swift/utils/update-checkout --clone  --scheme "swift-5.1-branch"
./swift/utils/build-toolchain swift_toolchain_ppc64le
cp -r $SWIFT_BUILD_DIR/swift-linux-powerpc64le/lib/swift/linux/powerpc64le/* $SWIFT_BUILD_DIR/swift-linux-powerpc64le/lib/swift/linux/

#Test toolchain to run all test suites.
./swift/utils/build-toolchain swift_toolchain_ppc64le --test
