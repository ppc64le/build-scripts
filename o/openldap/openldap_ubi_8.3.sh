# ----------------------------------------------------------------------------
#
# Package       : openldap
# Version       : 0.9.15
# Source repo   : https://github.com/openldap/openldap
# Language      : c,shell,c++
# Tested on     : UBI: 8.3
# Travis-Check  : True
# Script License: Apache License 2.0
# Maintainer's  : Balavva Mirji <Balavva.Mirji@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

# Variables
REPO=https://github.com/openldap/openldap

# Default tag for openldap
if [ -z "$1" ]; then
  export VERSION="LMDB_0.9.15"
else
  export VERSION="$1"
fi

# install tools and dependent packages
yum update -y
yum install -y git make autoconf automake libtool gcc-c++

# Cloning Repo
git clone $REPO
cd openldap
git checkout ${VERSION}
cd ./libraries/liblmdb

# Build and test package
mkdir -p /usr/local/man/man1
make
make install
make test
