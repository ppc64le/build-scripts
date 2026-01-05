#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : scala-collection-compat
# Version       : v2.12.0
# Source repo   : https://github.com/scala/scala-collection-compat
# Tested on	: UBI 9.3
# Language      : Scala
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Siddesh Sangodkar <siddesh.sangodkar1@ibm.com>

# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

# variables
PACKAGE_NAME=scala-collection-compat
PACKAGE_URL=https://github.com/scala/scala-collection-compat
PACKAGE_VERSION=${1:-v2.12.0}

#clear command line arguments
set --

# install tools and dependent packages
yum install -y git wget 
yum install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel java-1.8.0-openjdk-headless gcc-c++ jq cmake ncurses unzip make  gcc-gfortran

# setup java environment
export JAVA_HOME=$(compgen -G '/usr/lib/jvm/jre-1.8.0-openjdk-*')

# update the path env. variable 
export PATH="$JAVA_HOME/bin/":$PATH
export JAVA_OPTS="-Xms2048M -Xmx4096M -XX:MaxPermSize=4096M"
export SCALA_VERSION="2.13.13"
export SCALAJS_VERSION="1.5.0"
export SCALANATIVE_VERSION="0.4.0"
# Install sbt.
WDIR=`pwd`
wget https://repo.typesafe.com/typesafe/ivy-releases/org.scala-sbt/sbt-launch/0.13.18/sbt-launch.jar

echo '#!/bin/bash' > /tmp/sbt
echo 'SBT_OPTS="-server -Xms2048M -Xmx3G -Xss1m -XX:+CMSClassUnloadingEnabled -XX:+UseCompressedOops -XX:NewRatio=9 -XX:ReservedCodeCacheSize=100m"' >> /tmp/sbt
echo "java $SBT_OPTS -jar $WDIR/sbt-launch.jar \"$@\"" >> /tmp/sbt
chmod u+x /tmp/sbt


# clone, build and test specified version

#clone package
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Build
if ! /tmp/sbt compile ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi 

if ! /tmp/sbt test ; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
