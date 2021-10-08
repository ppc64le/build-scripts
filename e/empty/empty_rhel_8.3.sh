# Version       : 0.10.1
# Source        : https://github.com/iclanzan/empty.git
# Tested on     : RHEL 8.3
# Node Version  : v10.24.0
# Maintainer    : Mohit Pawar <mohit.pawar@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
# ----------------------------------------------------------------------------

set -e

# Install all dependencies.
yum clean all
yum -y update

export PACKAGE_VERSION=v0.10.1

# Install nvm
if [ ! -d ~/.nvm ]; then
        #Install the required dependencies
        yum install -y curl git make
        curl https://raw.githubusercontent.com/creationix/nvm/v0.33.0/install.sh | bash
fi

source ~/.nvm/nvm.sh

# Install node version v10.24.0
if [ `nvm list | grep -c "v10.24.0"` -eq 0 ]
then
        nvm install v10.24.0
fi

nvm alias default v10.24.0

# Install and test empty
git clone https://github.com/iclanzan/empty.git
cd empty/
#git checkout ${PACKAGE_VERSION}
# npm install -g yarn
npm install testem -g
npm install
npm test
