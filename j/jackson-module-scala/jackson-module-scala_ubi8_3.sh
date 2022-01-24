# ----------------------------------------------------------------------------
#
# Package       : jackson-module-scala
# Version       : jackson-module-scala-2.10.5
# Language      : Scala
# Source repo   : https://github.com/FasterXML/jackson-module-scala
# Tested on     : UBI 8.3
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

#Variables
PACKAGE_URL=https://github.com/FasterXML/jackson-module-scala.git
PACKAGE_VERSION="${1:-jackson-module-scala-2.10.5}"

#Install required files
yum install -y git 

#install sbt
rm -f /etc/yum.repos.d/bintray-rpm.repo
curl -L https://www.scala-sbt.org/sbt-rpm.repo > sbt-rpm.repo
mv sbt-rpm.repo /etc/yum.repos.d/
yum install -y sbt

#Cloning Repo
git clone $PACKAGE_URL
cd jackson-module-scala/
git checkout $PACKAGE_VERSION

#Build test package
sbt compile
sbt test

echo "Complete!"