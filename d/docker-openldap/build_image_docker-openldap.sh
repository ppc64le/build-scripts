#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: docker-openldap
# Version	: v1.5.0
# Source repo	: https://github.com/osixia/docker-openldap
# Tested on	: CentOS 8
# Language      : Shell
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer	: Atharv Phadnis <Atharv.Phadnis@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Install docker if not found
if ! [ $(command -v docker) ]; then
	sudo yum install -y docker
fi

# Install git if not found
if ! [ $(command -v git) ]; then
	sudo yum install -y git
fi

# Install make if not found
if ! [ $(command -v make) ]; then
	sudo yum install -y make
fi

git clone https://github.com/osixia/docker-openldap && cd docker-openldap

git checkout v1.5.0

sed -i -e "/PQCHECKER/Id" image/Dockerfile;

make build
