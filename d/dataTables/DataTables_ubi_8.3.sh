# ----------------------------------------------------------------------------
#
# Package       : DataTables
# Version       : 1.10.11
# Source repo   : https://github.com/DataTables/DataTables.git
# Tested on     : UBI: 8.3
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
REPO=https://github.com/DataTables/DataTables.git

# Default tag DataTables
if [ -z "$1" ]; then
  export VERSION="1.10.11"
else
  export VERSION="$1"
fi

# install tools and dependent packages
yum update -y
yum install -y git wget

# install node
wget "https://nodejs.org/dist/v12.22.4/node-v12.22.4-linux-ppc64le.tar.gz"
tar -xzf node-v12.22.4-linux-ppc64le.tar.gz
export PATH=$CWD/node-v12.22.4-linux-ppc64le/bin:$PATH

# Cloning Repo
git clone $REPO
cd ./DataTables
git checkout ${VERSION}

# Build package
npm install
# npm test
# No test cases found




