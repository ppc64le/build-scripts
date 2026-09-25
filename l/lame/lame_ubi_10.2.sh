#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : lame
# Version          : 4.0
# Source repo      : https://downloads.sourceforge.net/sourceforge/lame/lame/4.0.tar.gz
# Tested on        : UBI:10.2
# Language         : Python, C, C++
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Tejas Badjate <tejasBadjateIBM@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------------------------

# Variables
PACKAGE=lame
PACKAGE_VERSION=${1:-4.0}
PACKAGE_URL=https://downloads.sourceforge.net/sourceforge/$PACKAGE/$PACKAGE-$PACKAGE_VERSION.tar.gz
PACKAGE_DIR=$PACKAGE-$PACKAGE_VERSION
CURRENT_DIR=$(pwd)

# Install dependencies
echo "Installing dependencies..."
yum install -y wget make  autoconf automake libtool openssl-devel bzip2-devel libffi-devel zlib-devel krb5-devel cmake python3.14 python3.14-devel python3.14-pip

yum install gcc-toolset-15 gcc-toolset-15-gcc -y 

if [[ -f /opt/rh/gcc-toolset-15/enable ]]; then
    source /opt/rh/gcc-toolset-15/enable
elif [[ -d /opt/rh/gcc-toolset-15/root/usr/bin ]]; then
    export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"
    export LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64:$LD_LIBRARY_PATH"
else
    echo "ERROR: gcc-toolset-15 not found"
    exit 1
fi

export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"
export LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64:${LD_LIBRARY_PATH:-}"

export CC="/opt/rh/gcc-toolset-15/root/usr/bin/gcc"

cd $CURRENT_DIR
wget $PACKAGE_URL
tar -xvf $PACKAGE-$PACKAGE_VERSION.tar.gz
cd $PACKAGE-$PACKAGE_VERSION

mkdir prefix
export PREFIX=$(pwd)/prefix

export CPU_COUNT=$(nproc)

# Remove libtool files
find $PREFIX -name '*.la' -delete

export CFLAGS="-include locale.h $CFLAGS"

# Configure, build, and install LAME
echo "Configuring LAME..."
./configure --prefix=$PREFIX \
            --disable-dependency-tracking \
            --disable-debug \
            --disable-decoder \
            --enable-shared \
            --enable-static \
            --enable-nasm

echo "Building LAME..."
make -j$CPU_COUNT

echo "Installing LAME..."
make install -j$CPU_COUNT

# Set environment variables
echo "Setting environment variables..."
export LD_LIBRARY_PATH=$PREFIX/lib:$LD_LIBRARY_PATH
export PATH=$PREFIX/bin:$PATH

# Test LAME
echo "Testing LAME..."
if ! cd $PREFIX/bin/ && ./lame --genre-list testcase.mp3; then
    echo "------------------$PACKAGE:Test_Fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE"
    echo "$PACKAGE | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Test_Fails"
    exit 1
fi

# Remove libtool files
echo "Cleaning up..."
find $PREFIX -name '*.la' -delete
cd $CURRENT_DIR

echo "back to lame dir"
cd $CURRENT_DIR/lame-$PACKAGE_VERSION
mkdir -p local/lame
cp -r $PREFIX/* local/lame/

# Install setuptools and build the package
echo "Installing setuptools and build tools..."
python3.14 -m pip install setuptools build

#get pyproject.toml
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/l/lame/pyproject.toml
sed -i s/{PACKAGE_VERSION}/$PACKAGE_VERSION/g pyproject.toml
sed -i 's|^upstream = .*|upstream = "https://downloads.sourceforge.net/sourceforge/lame/lame/{PACKAGE_VERSION}.tar.gz"|' pyproject.toml

#install
if ! (python3.14 -m pip install .) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

echo "LAME installation and testing completed successfully."