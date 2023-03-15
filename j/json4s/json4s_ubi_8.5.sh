#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: jon4s
# Version	: v4.1.0-M2
# Source repo	: https://github.com/json4s/json4s
# Tested on	: UBI: 8.5
# Language      : Scala
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Muskaan Sheik <Muskaan.Sheik@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=json4s
PACKAGE_VERSION=${1:-v4.1.0-M2}
PACKAGE_URL=https://github.com/json4s/json4s

yum update -y
yum install -y curl git java-1.8.0-openjdk-devel nodejs nodejs-devel clang

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.352.b08-2.el8_7.ppc64le
export PATH=$PATH:$JAVA_HOME/bin

rm -f /etc/yum.repos.d/bintray-rpm.repo
curl -L https://www.scala-sbt.org/sbt-rpm.repo > sbt-rpm.repo
mv sbt-rpm.repo /etc/yum.repos.d/
yum install -y sbt

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
if ! sbt 'set resolvers += "Sonatype OSS Snapshots" at "https://oss.sonatype.org/content/repositories/snapshots"' test; then
	echo "Test fails"
	exit 2
else
	echo "Test successful"
	exit 0
fi
   