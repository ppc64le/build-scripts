#!/bin/bash -e
# --------------------------------------------------------------------
#
# Package         : kestrel
# Version         : openmp
# Source repo     : https://github.com/jakelangham/kestrel.git
# Tested on       : Ubuntu 22.04 (Power 10)
# Language        : C++ / GDAL / GEOS / Boost
# Travis-Check    : False
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
PACKAGE_VERSION="${1:-openmp}"
PACKAGE_URL="https://github.com/jakelangham/${PACKAGE_NAME}.git"
BUILD_HOME="$(pwd)"

# --------------------------------------------------------------------
# Update system
# --------------------------------------------------------------------
apt-get update

# --------------------------------------------------------------------
# Install Basic Tools
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
# Install IBM Advance Toolchain 16.0.5 (Ubuntu tarball)
# --------------------------------------------------------------------
wget -qO- https://public.dhe.ibm.com/software/server/POWER/Linux/toolchain/at/ubuntu/dists/jammy/615d762f.gpg.key | tee -a /etc/apt/trusted.gpg.d/615d762f.asc > /dev/null

APT_LINE="deb [signed-by=/etc/apt/trusted.gpg.d/615d762f.asc] https://public.dhe.ibm.com/software/server/POWER/Linux/toolchain/at/ubuntu jammy at16.0"

echo "${APT_LINE}" | tee -a /etc/apt/sources.list

apt-get update
apt-get install -y advance-toolchain-at16.0-runtime \
                 advance-toolchain-at16.0-devel \
                 advance-toolchain-at16.0-perf \
                 advance-toolchain-at16.0-mcore-libs
				 
# Validate the IBM Advance Toolchain Version
if [[ -x /opt/at16.0/bin/gcc && -x /opt/at16.0/bin/g++ ]]; then
    GCC_VERSION=$(/opt/at16.0/bin/gcc --version | head -n 1)
    GPP_VERSION=$(/opt/at16.0/bin/g++ --version | head -n 1)

    echo "[INFO] GCC Version:  $GCC_VERSION"
    echo "[INFO] G++ Version:  $GPP_VERSION"
fi

echo "[INFO] IBM Advance Toolchain (AT16.0) installed successfully"

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

# --------------------------------------------------------------------
# Apply patch to modify test settings and update architecture-specific flags
# --------------------------------------------------------------------
if [ -f "$BUILD_HOME/kestrel_openmp.patch" ]; then
    git apply "$BUILD_HOME/kestrel_openmp.patch"
    echo "[INFO] Patch file kestrel_openmp.patch applied; continuing."
else
    echo "[WARN] Patch file kestrel_openmp.patch not found; skipping."
fi

# --------------------------------------------------------------------
# Run autoreconf (bootstrapping)
# --------------------------------------------------------------------
autoreconf -fi

# --------------------------------------------------------------------
# Configure with OpenMP support along with architecture-specific flags
# --------------------------------------------------------------------
CC=/opt/at16.0/bin/gcc CXX=/opt/at16.0/bin/g++ CXXFLAGS="-O2 -fopenmp -mcpu=native -std=c++17" FCFLAGS="-O2 -fopenmp -mcpu=native" ./configure

# --------------------------------------------------------------------
# Build the Kestrel binary
# --------------------------------------------------------------------
ret=0
make PARAL=1 || ret=$?
if [ "$ret" -ne 0 ]; then
    echo "------------------${PACKAGE_NAME}:build_fails-------------------------------------"
    exit 1
fi

# --------------------------------------------------------------------
# Install the compiled binary system-wide
# --------------------------------------------------------------------
make PARAL=1 install || ret=$?
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
# Verify if the built Kestrel binary is linked with OpenMP support
# --------------------------------------------------------------------
echo "[INFO] Checking if Kestrel binary is linked with OpenMP (libgomp)..."
if ldd src/kestrel | grep -i libgomp; then
    echo "[PASS] libgomp (OpenMP support) is linked correctly."
else
    echo "[FAIL] libgomp not found. OpenMP support may be missing."
fi

# --------------------------------------------------------------------
# Smoke Test
# --------------------------------------------------------------------
BUILT_VERSION="$(./src/kestrel 2>&1 | grep -oP 'v\d+\.\d+\.\d+')"
echo "[SUCCESS] Kestrel build and test passed successfully for ${BUILT_VERSION} on Ubuntu 22.04 Power10."
