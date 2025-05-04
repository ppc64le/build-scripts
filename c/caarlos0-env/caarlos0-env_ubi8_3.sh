# ----------------------------------------------------------------------------
#
# Package       : caarlos0/env [caarlos0-env] 
# Version       : v6.9.1
# Language      : Go
# Source repo   : https://github.com/caarlos0/env
# Tested on     : UBI 8.3
# Script License: MIT License    
# Maintainer    : Varsha Aaynure <Varsha.Aaynure@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

#Variables
PACKAGE_URL=https://github.com/caarlos0/env.git
PACKAGE_VERSION="${1:-v6.9.1}"

#Install required files
sudo yum install -y golang

#Cloning Repo
git clone $PACKAGE_URL
cd env/
git checkout $PACKAGE_VERSION

#Build and test package
go build 
go test 

echo "Complete!"