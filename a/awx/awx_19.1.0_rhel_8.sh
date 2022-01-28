#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package	: ansible/awx
# Version	: 19.1.0
# Source repo	: https://github.com/ansible/awx
# Tested on	: RHEL 8.3
# Script License: Apache License, Version 2 or later
# Maintainer	: Shivani Junawane <shivanij@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

CURRENT_DIR=`pwd`
# Install all dependencies.
sudo yum -y update
sudo yum -y install git curl gcc python38-devel libffi-devel openssl-devel make python38-pip

# Install ansible
pip3 install ansible
pip3 install docker-compose


# Build the awx container
git clone https://github.com/ansible/awx/
cd awx
git checkout 19.1.0
git apply ../awx_19.1.0.patch
make docker-compose-build

# Note:
# Even if above make command fails with cffi errors, it generates the Dockerfile in the awx directory
# Then build the image using docker build command instead
# docker build -t awx:19.1.0 .
