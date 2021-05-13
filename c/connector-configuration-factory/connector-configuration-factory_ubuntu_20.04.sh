# ----------------------------------------------------------------------------
#
# Package       : connector-configuration-factory 
# Version       : V2.9
# Source repo   : https://github.com/odpi/egeria
# Tested on     : Ubuntu 20.04.1 LTS (Focal Fossa)
# Script License: Apache License, Version 2 or later
# Maintainer    : Nagesh Tarale <Nagesh.Tarale@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

export URL=https://github.com/odpi/egeria.git
export BRANCH="$1"
PKG_NAME=${URL##*/}

if [ -d $PKG_NAME ] ; then
  rm -rf $PKG_NAME
fi
# Verify the arguments passed from command line.

if [ $# -lt 1 ]
then
  echo "Usage: $0 branch or tag_name"
  exit 0
fi
echo "Branch is $1 and no of arguments $# "
if [ $# -gt 1 ]
then
        echo "Specify no of arguments correctly, USAGE: $0 BRANCH"
        exit 0
else
        echo "Cloning the target"
fi

# Build and test the package
# BRANCHES can be master, or any other tags supported. 

git clone --depth 1 --branch $BRANCH $URL --single-branch
cd $PKG_NAME
sudo mvn install -B -V
