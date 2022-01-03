# -----------------------------------------------------------------------------
#
# Package       : jest
# Version       : 9b9afadbbf7f0cf8f93d72656cba4b3288d0ae49 or tag: 25.2.3
# Source repo   : https://github.com/DefinitelyTyped/DefinitelyTyped.git
# Tested on     : UBI 8
# Script License: Apache License, Version 2 or later
# Maintainer    : Raju.Sah@ibm.com
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
yum update -y
yum -y install git npm
VERSION=${1:-9b9afadbbf7f0cf8f93d72656cba4b3288d0ae49}

#clone the repo.
git clone https://github.com/DefinitelyTyped/DefinitelyTyped.git  

npm install -g typescript dtslint
npm install -D tslib @types/jest
cd DefinitelyTyped/
git checkout $VERSION

#build the package
npm install jest -X test
# test the package
#Note: Test is getting fail on both architecture power and intel.
npm install
