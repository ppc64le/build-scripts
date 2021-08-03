# ----------------------------------------------------------------------------
#
# Package	: scala
# Version	: 2.11.12
# Source repo	: https://github.com/scala/scala.git
# Tested on	: rhel_8.3
# Script License: Apache License, Version 2 or later
# Maintainer	: Punith Basavarajaiah<Punith.Basavarajaiah@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


#!/bin/bash

# install tools and dependent packages
yum install -y git wget curl unzip nano vim make gcc gcc-c++

# install Java packages
yum install -y java java-devel

#Set java home
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.302.b08-0.el8_4.ppc64le
export PATH=$PATH:$JAVA_HOME/bin

#install sbt package
curl -L https://www.scala-sbt.org/sbt-rpm.repo > sbt-rpm.repo
mv sbt-rpm.repo /etc/yum.repos.d/
yum -y install sbt

#clone repository
cd ~
git clone https://github.com/scala/scala.git
cd scala/
echo "Enter the scala version:"
read Version
git checkout $Version

#compile and test the package
sbt compile
sbt test
