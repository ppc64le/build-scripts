# ----------------------------------------------------------------------------
#
# Package	: scalatest
# Version	: 3.0.3
# Source repo	: https://github.com/scalatest/scalatest
# Tested on	: rhel_7.3
# Script License: Apache License, Version 2 or later
# Maintainer	: Atul Sowani <sowania@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

# Install dependencies.
sudo yum update -y
sudo yum install -y git gcc wget make python java-1.8.0-openjdk-devel.ppc64le
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$JAVA_HOME/bin:$PATH
export JAVA_OPTS="-Xms2048M -Xmx4096M -XX:MaxPermSize=4096M"

# Install sbt.
WDIR=`pwd`
wget https://repo.typesafe.com/typesafe/ivy-releases/org.scala-sbt/sbt-launch/0.13.12/sbt-launch.jar

echo '#!/bin/bash' > /tmp/sbt
echo 'SBT_OPTS="-server -Xms2048M -Xmx3G -Xss1m -XX:+CMSClassUnloadingEnabled -XX:+UseCompressedOops -XX:NewRatio=9 -XX:ReservedCodeCacheSize=100m"' >> /tmp/sbt
echo "java $SBT_OPTS -jar $WDIR/sbt-launch.jar \"$@\"" >> /tmp/sbt
chmod u+x /tmp/sbt
/tmp/sbt | echo 0

sudo yum install -y ca-certificates*
sudo yum reinstall -y ca-certificates
sudo yum update ca-certificates

# Clone and build source code.
cd $WDIR
git clone https://github.com/scalatest/scalatest
cd scalatest
/tmp/sbt compile
/tmp/sbt test
