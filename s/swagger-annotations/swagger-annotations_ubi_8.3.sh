#----------------------------------------------------------------------------
#
# Package         : swagger-annotations
# Version         : v1.5.3
# Source repo     : https://github.com/swagger-api/swagger-core.git
# Tested on       : ubi:8.3
# Script License  : Apache License 2.0
# Maintainer      : srividya chittiboina <Srividya.Chittiboina@ibm.com>
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
#
# ----------------------------------------------------------------------------

REPO=https://github.com/swagger-api/swagger-core.git

# Default tag wagger-annotations
if [ -z "$1" ]; then
  export VERSION=" v1.5.3"
else
  export VERSION="$1"
fi



#Cloning Repo
git clone $REPO
cd modules/swagger-annotations
git checkout ${VERSION}
sed -i "s#<p/>#<p>#g" $(grep -Ril './' -e "<p/>")

#Build repo
mvn build
#Test repo
mvn test
 


         