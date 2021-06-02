# ----------------------------------------------------------------------------
#
# Package          : kubernetes-model-common
# Version          : 4.6.1
# Source repo      : https://mvnrepository.com/artifact/io.fabric8/kubernetes-model-common/4.6.1
# Tested on        : Ubuntu_18.04
# Passing Arguments: 1.Version of package
# Script License   : Apache License, Version 2 or later
# Maintainer       : Arumugam N S <asellappen@yahoo.com> / Priya Seth<sethp@us.ibm.com>
#
# Disclaimer       : This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash
export LOGS_DIRECTORY=/logs

#Version of package and default to 4.6.1
if [ -z "$1" ]; then
  export VERSION="4.6.1"
else
  export VERSION="$1"
fi

#For rerunning build
export FOLDER=kubernetes-model-common-$VERSION
if [ -d ${FOLDER} ] ; then
  echo "Removing existing paths logs, ${FOLDER}  to rerun..."
  rm -rf ${FOLDER}
else
  # create folder for saving logs and package folder with version
  mkdir -p /logs
  mkdir ${FOLDER}
fi

# Install Dependencies
sudo apt-get update -y
sudo apt-get install -y wget openjdk-8-jdk  maven

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-ppc64el
export PATH=$PATH:$JAVA_HOME/bin

# Download source-jar
cd ${FOLDER}
wget https://repo1.maven.org/maven2/io/fabric8/kubernetes-model-common/$VERSION/kubernetes-model-common-$VERSION.jar

jar -xvf kubernetes-model-common-$VERSION.jar
#remove jar which download from mvn
rm kubernetes-model-common-$VERSION.jar
#get pom to build
wget https://repo1.maven.org/maven2/io/fabric8/kubernetes-model-common/$VERSION/kubernetes-model-common-$VERSION.pom
mv kubernetes-model-common-$VERSION.pom pom.xml

# Build and Test
mvn clean install | tee $LOGS_DIRECTORY/kubernetes-model-common-$VERSION-build.log
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "Done build ..."
else
  echo  "Failed build ...."
  exit
fi

mvn test | tee $LOGS_DIRECTORY/kubernetes-model-common-$VERSION-test.log
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "Done Test ..."
else
  echo  "Failed Test..."
  exit
fi
