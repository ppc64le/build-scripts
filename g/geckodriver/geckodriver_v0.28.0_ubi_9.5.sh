#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : geckodriver
# Version       : v0.28.0
# Source repo   : https://github.com/mozilla/geckodriver
# Tested on     : UBI 9.5 (ppc64le)
# Language      : Rust
# Ci-Check  : true
# Script License: Apache License, Version 2 or later
# Maintainer    : Sanket Patil <Sanket.Patil11@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME="geckodriver"
PACKAGE_VERSION="v0.28.0"
PACKAGE_URL="https://github.com/mozilla/geckodriver"
WORK_DIR=$(pwd)
RUNTESTS=1

for arg in "$@"; do
  case $arg in
    --skip-tests)
      RUNTESTS=0
      echo "Skipping tests"
      ;;
    -*|--*)
      echo "Unknown option: $arg"
      exit 3
      ;;
    *)
      PACKAGE_VERSION=$arg
      ;;
  esac
done

yum install -y git curl gcc gcc-c++ make glibc-devel --allowerasing

curl https://sh.rustup.rs -sSf | sh -s -- -y
source $HOME/.cargo/env
export PATH=$PATH:/root/.cargo/bin

cd "$WORK_DIR"
git clone "$PACKAGE_URL"
cd "$PACKAGE_NAME"
git checkout "$PACKAGE_VERSION"

# Build the package
ret=0
cargo build --release || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "ERROR: $PACKAGE_NAME $PACKAGE_VERSION - Build failed."
    exit 1
else
    echo "INFO: $PACKAGE_NAME $PACKAGE_VERSION - Build successful."
fi

# Skip Tests?
if [ "$RUNTESTS" -eq 0 ]; then
    set +ex
    echo "Complete: $PACKAGE_NAME $PACKAGE_VERSION Build and install successful! Tests skipped."
    exit 0
fi

# Run tests
cargo test || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "ERROR: $PACKAGE_NAME $PACKAGE_VERSION - Test phase failed."
    exit 2
else
    echo "INFO: $PACKAGE_NAME $PACKAGE_VERSION - All tests passed."
fi

echo "SUCCESS: $PACKAGE_NAME version $PACKAGE_VERSION built and tested successfully."
exit 0
