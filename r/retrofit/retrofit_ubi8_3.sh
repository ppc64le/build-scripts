# ----------------------------------------------------------------------------
#
# Package       : retrofit
# Version       : parent-2.7.1
# Source repo   : https://github.com/square/retrofit
# Tested on     : ubi 8.3
# Script License: Apache-2.0 License
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
#
# ----------------------------------------------------------------------------

#Variables
REPO=https://github.com/square/retrofit.git

# Default tag Webassemblyjs
if [ -z "$1" ]; then
  export VERSION="parent-2.7.1"
else
  export VERSION="$1"
fi

yum update -y

#Install required files
yum install -y git maven

#Cloning Repo
git clone $REPO
cd retrofit/

git checkout ${VERSION}

#Build repo
mvn clean package

#Test repo
mvn test

