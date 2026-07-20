#!/bin/bash -ex
# --------------------------------------------------------------------------------
# Package        : valkey
# Version        : 9.0.1
# Source repo    : https://github.com/valkey-io/valkey
# Tested on      : UBI 9.6
# Language       : C,Tcl
# Ci-Check       : True
# Maintainer     : Pratik Tonage <Pratik.Tonage@ibm.com>
# Script License : Apache License, Version 2.0 or later
#
# Disclaimer     : This script has been tested in root mode on the specified
#                  platform and package version. Functionality with newer
#                  versions of the package or OS is not guaranteed.
# -------------------------------------------------------------------------------

# ---------------------------
# Configuration
# ---------------------------
PACKAGE_NAME="valkey"
PACKAGE_ORG="valkey-io"
PACKAGE_VERSION="9.0.1"
PACKAGE_URL="https://github.com/${PACKAGE_ORG}/${PACKAGE_NAME}.git"
RUNTESTS=1
BUILD_HOME="$(pwd)"

# -------------------
# Parse CLI Arguments
# -------------------
for i in "$@"; do
  case $i in
    --skip-tests)
      RUNTESTS=0
      echo "Skipping tests"
      shift
      ;;
    -*|--*)
      echo "Unknown option $i"
      exit 3
      ;;
    *)
      PACKAGE_VERSION=$i
      echo "Building ${PACKAGE_NAME} ${PACKAGE_VERSION}"
      ;;
  esac
done

# ---------------------------
# Dependency Installation
# ---------------------------
dnf -y install \
    git gcc gcc-c++ make glibc-devel \
    openssl openssl-libs systemd-devel \
    tar gzip shadow-utils findutils diffutils tzdata \
    librdmacm-devel libibverbs-devel tcl procps-ng
	
# ---------------------------
# Clone and Prepare Repository
# ---------------------------
cd "${BUILD_HOME}"

if [ ! -d "${PACKAGE_NAME}" ]; then
    git clone "${PACKAGE_URL}"
fi

cd "${PACKAGE_NAME}"
git checkout "${PACKAGE_VERSION}"

# --------
# Build
# --------
ret=0
make || ret=$?
if [ $ret -ne 0 ]; then
        set +ex
	echo "------------------ ${PACKAGE_NAME}: Build Failed! ------------------"
	exit 1
fi

VALKEY_BUILD_DIR="${BUILD_HOME}/${PACKAGE_NAME}/src"

# --------------------
# Installing Valkey
# --------------------
# Use make PREFIX=/some/other/directory install if you wish to use a different destination.
ret=0
make install || ret=$?
if [ $ret -ne 0 ]; then
        set +ex
        echo "------------------ Complete: Installation Failed!------------------"
        exit 2
fi

# ---------------------------
# Skip Tests?
# ---------------------------
if [ "$RUNTESTS" -eq 0 ]; then
        set +ex
        echo "Complete: Build and install successful!"
        echo "Valkey build artifacts (including valkey-server, valkey-cli) are available at [${VALKEY_BUILD_DIR}]"
        echo "Installed binaries are available at [/usr/local/bin]"
        exit 0
fi

# -------------------------------------
# Below runs the main integration tests
# -------------------------------------
ret=0
make test || ret=$?
if [ $ret -ne 0 ]; then
	set +ex
	echo "------------------ ${PACKAGE_NAME}: Integration Test Failed ------------------"
	exit 2
fi

# ------------
# Unit Tests
# ------------
ret=0
make test-unit || ret=$?
if [ $ret -ne 0 ]; then
	set +ex
	echo "------------------ ${PACKAGE_NAME}: Unit Test Failed ------------------"
	exit 2
fi

set +ex
echo "Complete: Build and Tests successful!"
echo "Instructions: https://github.com/${PACKAGE_ORG}/${PACKAGE_NAME}/blob/unstable/README.md"
