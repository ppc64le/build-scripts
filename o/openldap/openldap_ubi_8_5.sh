# ----------------------------------------------------------------------------
#
# Package       : openldap
# Version       : OPENLDAP_REL_ENG_2_6_3
# Source repo   : https://github.com/openldap/openldap
# Tested on     : UBI: 8.5
# Travis-Check  : True
# Language      : C
# Script License: Apache License 2.0
# Maintainer's  : Stuti.Wali@ibm.com
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
  export VERSION="OPENLDAP_REL_ENG_2_6_3"
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
cd /openldap/libraries/liblmdb

# Build and test package
mkdir -p /usr/local/man/man1
make
make install
make test
