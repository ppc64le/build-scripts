# ----------------------------------------------------------------------------
#
# Package         : Scala-Swing
# Version         : 
# Source repo     : https://github.com/scala/scala-swing
# Tested on       : 
# Script License  : 
# Maintainer      : 
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#! /bin/bash

yum update -y
yum install -y git curl

# setup java environment
yum install -y java java-devel
which java
ls /usr/lib/jvm/
export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-)(?=.*ppc64le)')
echo "JAVA_HOME is $JAVA_HOME"
# update the path env. variable 
export PATH=$PATH:$JAVA_HOME/bin


#install the prerequisite sbt
rm -f /etc/yum.repos.d/bintray-rpm.repo
curl -L https://www.scala-sbt.org/sbt-rpm.repo > sbt-rpm.repo
mv sbt-rpm.repo /etc/yum.repos.d/
yum install -y sbt

#clone the repo.

git clone https://github.com/scala/scala-swing
cd scala-swing/

#build and test repo
sbt clean swing/test swing/versionPolicyCheck swing/publishLocal
