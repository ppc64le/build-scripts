#----------------------------------------------------------------------------
#
# Package         : xerial/snappy-java
# Version         : 1.1.7.3
# Source repo     : https://github.com/xerial/snappy-java.git
# Tested on       : ubi:8.3
# Language        : Java, C++
# Travis-Check    : True
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
#Tested Versions:1.1.7.2, 1.1.7.3, 1.1.8.4
# ----------------------------------------------------------------------------

REPO=https://github.com/xerial/snappy-java.git

# Default tag snappy-java
if [ -z "$1" ]; then
  export VERSION="1.1.7.3"
else
  export VERSION="$1"
fi

yum update -y
yum install -y curl unzip wget git maven 
yum install -y java-11-openjdk.ppc64le java-11-openjdk-devel.ppc64le

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-11.0.12.0.7-0.el8_4.ppc64le
export PATH=$PATH:$JAVA_HOME/bin

#sbt installation
rm -f /etc/yum.repos.d/bintray-rpm.repo
curl -L https://www.scala-sbt.org/sbt-rpm.repo > sbt-rpm.repo
mv sbt-rpm.repo /etc/yum.repos.d/
yum install -y sbt
#Cloning Repo
git clone $REPO
cd  snappy-java/
git checkout ${VERSION}

#Build repo
sbt compile
#Test repo
sbt test


         