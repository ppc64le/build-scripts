#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package       : shiny-server
# Version       : v1.5.23.1030
# Source repo   : https://github.com/rstudio/shiny-server
# Tested on     : UBI:9.3
# Language      : Java/C++
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Guarav.Bankar@ibm.com
#
# Disclaimer: This script has been tested in user mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_URL=https://github.com/rstudio/shiny-server
PACKAGE_NAME=shiny-server
PACKAGE_VERSION=${1:-v1.5.23.1030}
export ARCH=$(uname -m)
TMPWS_DIR=$HOME

# Install required packages
echo "Installing required dependencies..."
yum install -y gcc gcc-c++ gcc-gfortran git wget xz cmake make yum-utils python3 python3-devel llvm sudo npm nodejs

git clone $PACKAGE_URL ${TMPWS_DIR}/$PACKAGE_NAME
cd ${TMPWS_DIR}/$PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Node installation via NVM
export NODE_VERSION=${NODE_VERSION:-20}
echo "Installing Node.js version $NODE_VERSION..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source "$HOME/.bashrc"
nvm install "$NODE_VERSION" >/dev/null
nvm use $NODE_VERSION

# Update PATH to include local binaries and Python
echo "Updating PATH..."
export PATH=$(pwd)/../bin:$PATH
PYTHON=$(which python3)
export PATH=$PYTHON:$PATH

# Build the Shiny Server
cmake -DCMAKE_INSTALL_PREFIX=/usr/local -DPYTHON="$PYTHON"

if ! make ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

mkdir build
npm ci --omit-dev

# Install Shiny server
if ! make install; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 1
fi

# Create a tarball of the installed Shiny server
cd ${TMPWS_DIR}
tar czf shiny_server_${ARCH}_${PACKAGE_VERSION}.tar.gz /usr/local/shiny-server

# Create startup script
echo "Creating startup script..."
echo 'echo -a "wsl-shiny-container-${HOSTNAME}-is-up" sh & tail -f /dev/null & wait' > ~/startup.sh
chmod 755 ~/startup.sh


# Copy configuration files
mkdir -p /etc/shiny-server
cp ${TMPWS_DIR}/shiny-server/config/default.config /etc/shiny-server/shiny-server.conf
ln -s /usr/local/shiny-server/bin/shiny-server /usr/bin/shiny-server

# Configure Shiny Server
echo "Configuring Shiny server..."
useradd -r -m shiny
mkdir -p /var/log/shiny-server /srv/shiny-server /var/lib/shiny-server /etc/shiny-server
chown shiny /var/log/shiny-server
chown shiny ${TMPWS_DIR}/shiny-server/

# Start Shiny Server
echo "Starting Shiny Server..."
if ! (shiny-server &); then
    echo "------------------$PACKAGE_NAME:start_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Start_Fails"
    exit 1
fi

# Run tests as shiny user
rm -rf /srv/shiny-server/*
cd /srv/shiny-server/
cp -r ${TMPWS_DIR}/shiny-server/* /srv/shiny-server/
chown -R shiny:shiny /srv/shiny-server

if !(sudo -E -u shiny bash -c "set -xe; cd /srv/shiny-server && npm install && npm test"); then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    echo "Shiny server setup and testing complete."
    exit 0
fi

