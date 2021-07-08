# ----------------------------------------------------------------------------
#
# Package       : breakpad
# Version       : https://chromium-review.googlesource.com/c/breakpad/breakpad/+/1426283/21
# Source repo   : https://chromium.googlesource.com/breakpad/breakpad
# Tested on     : Red Hat Enterprise Linux release 8.3 (Ootpa)
# Script License: Apache License, Version 2 or later
# Maintainer    : Amit Shirodkar <amit.shirodkar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


#!/bin/bash

#breakpad build script

git clone https://chromium.googlesource.com/breakpad/breakpad

#fetch , patch and copy linux-syscall-support
git clone https://chromium.googlesource.com/linux-syscall-support
cd linux-syscall-support/
git fetch https://chromium.googlesource.com/linux-syscall-support refs/changes/73/1430973/4 && git checkout FETCH_HEAD
cd ../breakpad
mkdir -p src/third_party/lss
cp ../linux-syscall-support/linux_syscall_support.h src/third_party/lss/

cd ..

# download google test and copy the contents to breakpad/src/testing - needed for make check
wget https://github.com/google/googletest/archive/refs/tags/release-1.8.1.tar.gz
tar -xvf release-1.8.1.tar.gz
mkdir -p breakpad/src/testing
cp -r googletest-release-1.8.1/google* breakpad/src/testing

cd breakpad
#fetch patch 21 https://chromium-review.googlesource.com/c/breakpad/breakpad/+/1426283/21
git fetch https://chromium.googlesource.com/breakpad/breakpad refs/changes/83/1426283/21 && git checkout FETCH_HEAD
./configure
make
make check

