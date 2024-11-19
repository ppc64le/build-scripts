#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : dbus
# Version          : 1.13.16
# Source repo      : http://dbus.freedesktop.org/releases/dbus/
# Tested on        : UBI:9.3
# Language         : Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Rakshith R <rakshith.r5@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------
# Variables
PACKAGE_NAME=dbus
PACKAGE_VERSION=${1:-1.13.16}
PACKAGE_URL=http://dbus.freedesktop.org/releases/dbus/

# Step 1: Install Build Dependencies
dnf groupinstall "Development Tools"
dnf install \
    wget \
    xz \
    glibc-devel \
    dbus-devel \
    pkgconfig \
    automake \
    autoconf \
    libtool \
    cairo-devel \
    libxml2-devel \
    gperf \
    gcc-c++ \
    make \
    expat-devel  

# Step 2: Download the Source Code
# Download the dbus tarball from the official website.
# wget http://dbus.freedesktop.org/releases/dbus/dbus-1.13.16.tar.xz
wget http://dbus.freedesktop.org/releases/dbus/$PACKAGE_NAME-$PACKAGE_VERSION.tar.xz

# Step 3: Extract the Tarball
# Extract the tarball to a directory
tar -xf $PACKAGE_NAME-$PACKAGE_VERSION.tar.xz
cd $PACKAGE_NAME-$PACKAGE_VERSION

# Step 4: Prepare Build Environment
# Configure the build. Here, we install locally into $HOME/.local.
# This ensures you don't need root privileges. You can also choose other directories.
./configure --prefix=$HOME/.local

# Step 5: Build the Source Code
# Build the source using `make`.
make

# Step 6: Install the Package Locally
# Install the compiled files into $HOME/.local (instead of system-wide /usr).
make install

# Step 7: Verify the Installation
# Check the installed binaries and make sure they are in the correct location.
ls $HOME/.local/bin

# Step 8: Update PATH and LD_LIBRARY_PATH
# After installation, make sure the binaries are in your user environment.
# Add the installation directories to PATH.
echo 'export PATH=$HOME/.local/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# Step 9: Verify the Installation
# Check the dbus version to confirm the installation was successful.
dbus-daemon --version
