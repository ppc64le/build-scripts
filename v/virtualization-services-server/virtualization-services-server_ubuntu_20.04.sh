# ----------------------------------------------------------------------------
#
# Package       : virtualization-services-server
# Version       : egeria-release-2.10 
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
PKG_NAME=${PKG_NAME%%.*}

if [ -d $PKG_NAME ] ; then
  rm -rf $PKG_NAME
fi
# Verify the arguments passed from command line.

if [ $# -lt 1 ]
then
  echo "Usage: $0 branch or tag_name >> For specific versions, default is master"
  BRANCH="master"
#  exit 0
fi
#echo "Branch is $1 and no of arguments $# "
if [ $# -gt 1 ]
then
        echo "Specify no of arguments for specific versions by default it will be master, USAGE: $0 BRANCH"
        exit 0
else
        echo "Cloning the target"
fi

# Build and test the package
# BRANCHES can be master, or any other tags supported.
# Ex : egeria-release-2.10 , egeria-release-2.9, master etc
git clone --depth 1 --branch $BRANCH $URL --single-branch
sudo mvn install -B -V   # This will build the required dependent packages.
cd $PKG_NAME/open-metadata-implementation/governance-servers/virtualization-services/virtualization-services-server
sudo mvn package
# The above command will build the virtualization-services as it is not build via mvn install command. This has to be build implicitly.
