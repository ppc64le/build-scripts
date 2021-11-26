# ----------------------------------------------------------------------------
#
# Package       : Jackson-datatype-Guava
# Version       : 2.13
# Source repo   : https://github.com/FasterXML/jackson-datatypes-collections
# Tested on     : ubi: 8.3
# Script License: Apache License 2.0
# Maintainer's  : Hari Pithani <Hari.Pithani@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

echo "Usage: $0 [<VERSION>]"
echo "       PACKAGE_VERSION is an optional paramater whose default value is 2.13"

export REPO=https://github.com/FasterXML/jackson-datatypes-collections.git

#Default tag jacoco
if [ -z "$1" ]; then
  export VERSION="2.13"
else
  export VERSION="$1"
fi

# Installation of required sotwares.
yum update -y
yum install git wget java-11-openjdk-devel -y
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-11.0.12.0.7-0.el8_4.ppc64le
export PATH=$PATH:$JAVA_HOME/bin

# Maven installation steps.
wget https://dlcdn.apache.org/maven/maven-3/3.8.3/binaries/apache-maven-3.8.3-bin.tar.gz
tar -C /usr/local/ -xzvf apache-maven-3.8.3-bin.tar.gz
rm -rf tar xzvf apache-maven-3.8.3-bin.tar.gz
mv /usr/local/apache-maven-3.8.3 /usr/local/maven
export M2_HOME=/usr/local/maven
export PATH=$PATH:$M2_HOME/bin

#For rerunning build
if [ -d "jackson-datatypes-collections" ] ; then
  rm -rf jackson-datatypes-collections
fi

git clone ${REPO}
cd jackson-datatypes-collections/guava
git checkout ${VERSION}
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "${VERSION} found to checkout"
else
  echo  "${VERSION} not found"
  exit
fi

mvn test -B
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "Done Test ......"
else
  echo  "Failed Test ......"
fi

mvn install -DskipTests
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "Done build ..."
else
  echo  "Failed build......"
  exit
fi


