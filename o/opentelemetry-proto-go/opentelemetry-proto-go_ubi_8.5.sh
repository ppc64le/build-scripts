#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package	: opentelemetry-proto-go
# Version	: otlp/v0.19.0
# Source repo	: https://github.com/open-telemetry/opentelemetry-proto-go
# Tested on	: ubi 8.5
# Language      : go
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer	: Adilhusain Shaikh <Adilhusain.Shaikh@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME="opentelemetry-proto-go"
PACKAGE_VERSION=${1:-"otlp/v0.19.0"}
PACKAGE_URL="https://github.com/open-telemetry/opentelemetry-proto-go"
HOME_DIR=$PWD

echo "Installing required repos..."
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

echo "installing required pkgs..."
dnf install -qy docker-ce make git golang rsync

systemctl start docker

git clone -q $PACKAGE_URL $PACKAGE_NAME
cd $PACKAGE_NAME
git checkout "$PACKAGE_VERSION"
git submodule update --init --recursive
export OTEL_BUILD_PROTOBUF_VERSION=$(grep otel/build-protobuf Makefile | cut -d ":" -f2)
cd "$HOME_DIR"
git clone -q https://github.com/open-telemetry/build-tools
cd build-tools
git checkout v"$OTEL_BUILD_PROTOBUF_VERSION"
git apply "$HOME_DIR"/patch_build_tools

docker build -t otel/build-protobuf:"$OTEL_BUILD_PROTOBUF_VERSION" ./protobuf
cd "$HOME_DIR"/$PACKAGE_NAME
if make; then
    echo "build passes for $PACKAGE_NAME"
else
    echo "build fails for $PACKAGE_NAME"
fi
