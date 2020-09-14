# ----------------------------------------------------------------------------
#
# Package       : node
# Version       : 10.15.3
# Source repo   : https://github.com/nodejs/node
# Tested on     : rhel 7.6
# Script License: Apache License Version 2.0
# Maintainer    : Shivani Junawane <shivanij@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash



# install dependencies
yum update -y && yum install -y git subscription-manager

# enable repository to install devtoolset8
subscription-manager repos --enable rhel-7-server-optional-rpms \
    --enable rhel-server-rhscl-7-rpms \
    --enable rhel-7-server-devtools-rpms
yum install -y devtoolset-8 
# below command also works but opens a new login shell - and exits the script.
#scl enable devtoolset-8 'bash'
source /opt/rh/devtoolset-8/enable


# install node
git clone https://github.com/nodejs/node.git
cd node
git checkout v10.15.3
./configure
make -j4

# tests to verify build
make test-only




