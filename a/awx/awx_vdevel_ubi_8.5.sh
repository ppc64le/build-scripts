#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: ansible/awx
# Version	: devel
# Source repo	: https://github.com/ansible/awx
# Tested on	: UBI: 8.5
# Language      : Python
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer	: Sunidhi Gaonkar<Sunidhi.Gaonkar@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=awx
PACKAGE_VERSION=${1:-devel}
PACKAGE_URL=https://github.com/ansible/awx/

CURRENT_DIR=`pwd`
SCRIPT=$(readlink -f $0)
SCRIPT_DIR=$(dirname $SCRIPT)
# Install all dependencies.
sudo yum -y update
sudo yum -y install git curl gcc libffi-devel openssl-devel make python39-devel python39-pip 

# Install ansible
pip3 install setuptools-rust
curl https://sh.rustup.rs -sSf | sh -s -- -y
PATH="$HOME/.cargo/bin:$PATH"
source $HOME/.cargo/env
pip3 install ansible
pip3 install docker-compose


# Build the awx container
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git apply $SCRIPT_DIR/awx_devel.diff
make docker-compose-build

# Travis check is set to false as the script needs to be run on VM.
# **************test*************
# The code for testing is commented as it uses the command "make docker-compose" which never finishes and requires user interruption.
# Use the following command to pull required images and start containers for validation.
#  make docker-compose
# In a new terminal run the command "docker exec tools_awx_1 make clean-ui ui-devel" to build the UI.
# User interruption will be required to exit make docker-compose.
# Run "make docker-compose-test" to start a new container for testing.
# for unit tests run "make test_unit" and for functional tests "make test_coverage" inside the new container created.