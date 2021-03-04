# ----------------------------------------------------------------------------
#
# Package       : psycopg2cffi
# Version       : 2.9.0
# Source repo   : https://github.com/chtd/psycopg2cffi
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

# Install python3
yum update -y
yum install ${PYTHON} ${PYTHON}-devel ${PYTHON}-pip -y

# Install dependencies for psycopg2cffi
yum install gcc postgresql-devel libffi-devel ${PYTHON}-cffi -y

# Add pg_config to the $PATH
export PATH="$HOME/usr/bin/pg_config:$PATH"

${PIP} install psycopg2cffi
