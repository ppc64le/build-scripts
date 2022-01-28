# ----------------------------------------------------------------------------
#
# Package       : antlr-runtime-3.4.jar
# Version       : 3.5.2
# Source repo   : https://github.com/antlr/antlr3.git
# Tested on     : Ubuntu_18.04
# Script License   : Apache License, Version 2 or later
# Maintainer    : Kishor Kunal Raj <kishore.kunal.mr@ibm.com> / Priya Seth<sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#/bin/bash
# variables
JAVA_VER="openjdk-8-jdk"
PKG_NAME="antlr-runtime"
LOGS_DIRECTORY=/logs
REPOSITORY="https://github.com/antlr/antlr3.git"


sudo apt update -y
sudo apt install -y git wget curl unzip nano vim make build-essential

#Setting java environment
sudo apt install -y ${JAVA_VER}
jret=$?
if [ $jret -eq 0 ] ; then
  echo "Sucessfully installed JDK  ${JAVA_VER} "
else
  echo "Failed to install JDK  ${JAVA_VER} "
  exit
fi

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el
export PATH=$JAVA_HOME/bin:$PATH

#Installing maven
sudo apt install -y maven
#export PATH=$PATH:/usr/share/maven/bin

# create folder for saving logs
sudo mkdir -p /logs

if [ -z "$1" ]; then
  export PKG_VERSION="master"
else
  export PKG_VERSION="$1"
fi

#For rerunning build
if [ -d ~/$PKG_NAME-$PKG_VERSION ] ; then
  sudo rm -rf ~/$PKG_NAME-$PKG_VERSION
  sudo rm -rf $LOGS_DIRECTORY/$PKG_NAME-$PKG_VERSION.txt
fi

# clone, build and test specified version
cd ~
git clone $REPOSITORY $PKG_NAME-$PKG_VERSION
cd $PKG_NAME-$PKG_VERSION/
git checkout -b $PKG_VERSION tags/$PKG_VERSION
cd runtime/Java/
sudo mvn install | sudo  tee $LOGS_DIRECTORY/$PKG_NAME-$PKG_VERSION.txt
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "Build successful, log and jar file created....."
else
  echo  "Failed to  build......"
  exit
fi
