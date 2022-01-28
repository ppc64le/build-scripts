# ----------------------------------------------------------------------------
#
# Package       : animal-sniffer
# Version       : master
# Source repo   : https://github.com/mojohaus/animal-sniffer
# Tested on     : Ubuntu 20.04.1 LTS (Focal Fossa)
# Script License: MIT License
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

export URL=https://github.com/mojohaus/animal-sniffer.git
PKG_NAME=${URL##*/}
PKG_NAME=${PKG_NAME%%.*}   
if [ -d $PKG_NAME ] ; then
  rm -rf $PKG_NAME
fi

#If TAG or BRANCH is not specified use default as master.
if [ -z "$1" ]; then
  export BRANCH="master"
else
  export BRANCH="$1"
fi

#Clean and Install Updates
sudo apt-get clean
sudo apt-get update
sudo apt-get install maven

# Verify the arguments passed from command line.
if [ $# -gt 1 ]
then
        echo "Specify no of arguments correctly, USAGE: $0 BRANCH or TAG"
        exit 0
else
        echo "Cloning the target"
fi

# Build and test the package
# BRANCHES can be master, or any tags available ex : animal-sniffer-parent-1.20, animal-sniffer-parent-1.19 etc.

git clone --depth 1 --branch $BRANCH $URL --single-branch
cd $PKG_NAME
sudo mvn install -B -V

# NOTE : The package dont have test specific files hence above command is sufficient to build the package and required jar file.
# After build is successful it will generate the ./animal-sniffer-annotations/target/animal-sniffer-annotations-1.21-SNAPSHOT.jar
# file.
