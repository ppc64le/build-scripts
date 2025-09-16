#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : fullcalendar
# Version       : v6.1.17
# Source repo   : https://github.com/fullcalendar/fullcalendar
# Tested on     : UBI 9.3 (ppc64le)
# Language      : JavaScript
# Travis-Check  : true
# Script License: Apache License, Version 2 or later
# Maintainer    : Amit Kumar <amit.kumar282@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=fullcalendar
PACKAGE_VERSION="v6.1.17"
PACKAGE_URL=https://github.com/fullcalendar/fullcalendar.git
BUILD_DIR=$(pwd)
SCRIPT_PATH=$(dirname $(realpath $0))
RUNTESTS=1

for arg in "$@"; do
  case "$arg" in
    --skip-tests)
      RUNTESTS=0
      echo "INFO: Tests will be skipped."
      shift
      ;;
    -*|--*)
      echo "Unknown option: $arg"
      exit 3
      ;;
  esac
done

# Install Repos and Dependencies
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os
rpm --import https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

yum install -y git tar jq firefox

export FIREFOX_BIN=$(which firefox)
export TZ=Asia/Kolkata
export TURBO_VERSION=1.4.4

# Install Node.js manually (compatible version)
export NODE_VERSION=20.14.0
cd /tmp
curl -O https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-ppc64le.tar.gz
tar -xzf node-v$NODE_VERSION-linux-ppc64le.tar.gz
export PATH=/tmp/node-v$NODE_VERSION-linux-ppc64le/bin:$PATH

# Install compatible pnpm
npm install -g pnpm@9.14.4

# Clone the fullcalendar repo
cd $BUILD_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

git apply ${SCRIPT_PATH}/${PACKAGE_NAME}_${PACKAGE_VERSION}_porting.patch

#Set Up Dependencies for FullCalendar Build
pnpm install
pnpm add -Dw karma-firefox-launcher
ln -sf /fullcalendar/node_modules/.pnpm/turbo-linux-ppc64le@${TURBO_VERSION}/node_modules/turbo-linux-ppc64le/bin/turbo \
       /fullcalendar/scripts/node_modules/.bin/turbo

# Build the project.
ret=0
pnpm run build || ret=$?
if [ "$ret" -ne 0 ]
then
	exit 1
fi

# Install the Package
export PNPM_HOME=/usr/local/pnpm-global
mkdir -p "$PNPM_HOME"
export PATH="$PNPM_HOME:$PATH"
echo "Installing ${PACKAGE_NAME}"

PACKAGE_DIR="bundle"
PACKAGE_TGZ_NAME="${PACKAGE_NAME}-${PACKAGE_VERSION#v}.tgz"
cd $PACKAGE_DIR
pnpm pack
pnpm install -g file:"$(realpath ./dist/"$PACKAGE_TGZ_NAME")" || ret=$?

if [ $? -eq 0 ]; then
  echo "Package installed successfully."
else
  echo "Installation failed."
  exit 3
fi

#Skip tests
if [ "$RUNTESTS" -eq 0 ]; then
    set +ex
    echo "Complete: Build and install successful! Tests skipped."
    exit 0
fi

# Run tests
pnpm -w run test || ret=$?
if [ "$ret" -ne 0 ]
then
	exit 2
fi

# Smoke test
BUILD_VERSION=$(jq -r .version package.json)
echo "SUCCESS: ${PACKAGE_NAME}_$BUILD_VERSION built and tested successfully!"
