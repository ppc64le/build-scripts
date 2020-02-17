#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package	: ansible/awx
# Version	: 9.0.1
# Source repo	: https://github.com/seth-priya/awx
# Tested on	: RHEL 7.7
# Script License: Apache License, Version 2 or later
# Maintainer	: Sarvesh Tamba <sarvesh.tamba@ibm.com>
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
sudo yum -y install git curl gcc python3-devel libffi-devel openssl-devel make ansible python3-pip
 
#The above pulls Intel specific rabbitmq image from DockerHub instead of being built locally.
#Build rabbitmq on Power and retag it.
cd $CURRENT_DIR
git clone https://github.com/ansible/awx-rabbitmq
cd awx-rabbitmq/
docker rmi ansible/awx_rabbitmq:3.7.4 ansible/awx_rabbitmq:latest -f
make
docker tag ansible/awx_rabbitmq:3.7.21 ansible/awx_rabbitmq:3.7.4

# Clone and build missing dependencies from source.
cd $CURRENT_DIR
git clone https://github.com/seth-priya/awx.git
cd awx
git apply ../awx_ppc64le.diff
pip install docker-compose
cd installer
ansible-playbook -i inventory install.yml