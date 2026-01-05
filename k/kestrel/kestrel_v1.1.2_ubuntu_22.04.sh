#!/bin/bash -e
# --------------------------------------------------------------------
#
# Package         : kestrel
# Version         : v1.1.2
# Source repo     : https://github.com/jakelangham/kestrel.git
# Tested on       : Ubuntu 22.04 (Power 10)
# Language        : C++ / GDAL / GEOS / Boost
# Ci-Check    : False
# Script License  : Apache License, Version 2 or later
# Maintainer      : Amit Kumar <amit.kumar282@ibm.com>
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
PACKAGE_NAME="kestrel"
PACKAGE_VERSION="${1:-v1.1.2}"
PACKAGE_URL="https://github.com/jakelangham/${PACKAGE_NAME}.git"
BUILD_HOME="$(pwd)"

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
# Install Core Libraries Required by Kestrel
# --------------------------------------------------------------------
apt-get install -y \
    libboost-all-dev libgeos-dev libproj-dev libpng-dev libjpeg-dev libcfitsio-dev libgif-dev \
    libopenjp2-7-dev libhdf4-dev libhdf5-dev libnetcdff-dev libpcre2-dev libarmadillo-dev

# --------------------------------------------------------------------
# Install Optional/Extended Libraries for Features (XML, DB, etc.)
# --------------------------------------------------------------------
apt-get install -y \
    libxerces-c-dev unixodbc-dev libkml-dev libwebp-dev libjson-c-dev libpoppler-dev \
    libgeotiff-dev libpq-dev libldap2-dev

# --------------------------------------------------------------------
# Install GDAL from APT
# --------------------------------------------------------------------
apt-get install -y gdal-bin libgdal-dev
echo "[INFO] GDAL Version: $(gdal-config --version)"

# --------------------------------------------------------------------
# Download and install Julia v1.11.6 for ppc64le
# --------------------------------------------------------------------
cd /tmp
wget https://julialang-s3.julialang.org/bin/linux/ppc64le/1.11/julia-1.11.6-linux-ppc64le.tar.gz
tar -xvzf julia-1.11.6-linux-ppc64le.tar.gz
mv julia-1.11.6 /opt/julia-1.11.6
ln -sf /opt/julia-1.11.6/bin/julia /usr/local/bin/julia

echo "[INFO] Julia Version: $(julia --version)"

# --------------------------------------------------------------------
# Clone kestrel repository from openmp branch
# --------------------------------------------------------------------
cd "$BUILD_HOME"
git clone --branch openmp "$PACKAGE_URL"
cd "$PACKAGE_NAME"
git checkout "$PACKAGE_VERSION"

# --------------------------------------------------------------------
# Run autoreconf (bootstrapping)
# --------------------------------------------------------------------
autoreconf -fi

# --------------------------------------------------------------------
# Modify Makefile.am to update architecture-specific flags (if needed)
# --------------------------------------------------------------------
if grep -q -- "-march=native" src/Makefile.am; then
    echo "[INFO] Replacing -march=native with -mcpu=native for Power architecture"
    sed -i 's/-march=native/-mcpu=native/g' src/Makefile.am
fi

# --------------------------------------------------------------------
# Configure with OpenMP support
# --------------------------------------------------------------------
./configure CXXFLAGS="-O2 -fopenmp -mcpu=native" FCFLAGS="-O2 -fopenmp -mcpu=native"

# --------------------------------------------------------------------
# Build the Kestrel binary
# --------------------------------------------------------------------
ret=0
make || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "------------------${PACKAGE_NAME}:build_fails-------------------------------------"
    exit 1
fi

# --------------------------------------------------------------------
# Install the compiled binary system-wide
# --------------------------------------------------------------------
make install || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "------------------${PACKAGE_NAME}:install_fails-------------------------------------"
    exit 1
fi

# --------------------------------------------------------------------
# Run Kestrel test suite using Julia
# --------------------------------------------------------------------
make check || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "------------------${PACKAGE_NAME}:tests_fails-------------------------------------"
    exit 2
fi

# --------------------------------------------------------------------
# Smoke Test
# --------------------------------------------------------------------
BUILT_VERSION="$(./src/kestrel 2>&1 | grep -oP 'v\d+\.\d+\.\d+')"
echo "[SUCCESS] Kestrel build and test passed successfully for ${BUILT_VERSION} on Ubuntu 22.04 Power10."
