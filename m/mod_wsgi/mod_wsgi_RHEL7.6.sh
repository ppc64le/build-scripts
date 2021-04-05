# ----------------------------------------------------------------------------
#
# Package       : mod_wsgi
# Version       : 4.7.1
# Source repo   : https://github.com/GrahamDumpleton/mod_wsgi
# Tested on     : RHEL 7.6, RHEL 7.7
# Script License: Apache License, Version 2 or later
# Maintainer    : Vedang Wartikar <vedang.wartikar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

export PYTHON=python3
export PIP=pip3
export REPO=https://github.com/GrahamDumpleton/mod_wsgi
export VERSION=4.7.1

yum update -y

# install python
yum install ${PYTHON} ${PYTHON}-devel ${PYTHON}-pip -y

# install mod_wsgi and related dependencies
yum install ${PYTHON}-mod_wsgi httpd httpd-devel gcc redhat-rpm-config -y

# install latest release for testing
yum install wget -y
${PIP} install tox
wget -c ${REPO}/archive/refs/tags/${VERSION}.tar.gz -O - | tar -xz
cd mod_wsgi-${VERSION}
tox -e py36