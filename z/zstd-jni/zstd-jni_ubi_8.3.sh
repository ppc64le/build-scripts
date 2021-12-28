#----------------------------------------------------------------------------
#
# Package         : luben/zstd-jni
# Version         : v1.5.0-4
# Source repo     : https://github.com/luben/zstd-jni.git
# Tested on       : ubi:8.3
# Script License  : BSD License
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
# ----------------------------------------------------------------------------

REPO=https://github.com/luben/zstd-jni.git

# Default tag zstd-jni
if [ -z "$1" ]; then
  export VERSION="v1.5.0-4"
else
  export VERSION="$1"
fi

yum install git  -y
yum install java-11-openjdk-devel -y
yum install gcc -y
#sbt installation
rm -f /etc/yum.repos.d/bintray-rpm.repo
curl -L https://www.scala-sbt.org/sbt-rpm.repo > sbt-rpm.repo
mv sbt-rpm.repo /etc/yum.repos.d/
yum install -y sbt
#Cloning Repo
git clone $REPO
cd  zstd-jni/
git checkout ${VERSION}

#Build Test repo
./sbt compile test package


         