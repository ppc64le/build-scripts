# ------------------------------------------------------------------------------------------
# Package          : spring-boot
# Version          : 2.5.0
# Source repo      : https://github.com/spring-projects/spring-boot
# Tested on        : ubuntu_20.04
# Passing Arguments: 1.Version of package, 2.JDK version (openjdk-8-jdk or openjdk-11-jdk)
#                    3.Module list to be build(list of modules in single quote listed with space)
# Modlues covered  : spring-boot-starter spring-boot-starter-actuator spring-boot-starter-jdbc spring-boot-starter-json spring-boot-starter-log4j2 spring-boot-starter-logging spring-boot-starter-security spring-boot-starter-validation spring-boot-starter-web
# Script License   : Apache License, Version 2 or later
# Maintainer       : Arumugam N S <asellappen@yahoo.com> / Priya Seth<sethp@us.ibm.com>
#
# Disclaimer       : This script has been tested in non-root mode on given
# ==========   platform using the mentioned version of the package.It may not
#              work as expected with newer versions of the package and/or distribution.
#              In such case, please contact "Maintainer" of this script.
#
# ------------------------------------------------------------------------------------------
#!/bin/bash

# variables
export REPO=https://github.com/spring-projects/spring-boot
export PKG_NAME="spring-boot-starter"
export LOGS_DIRECTORY=/logs

# create folder for saving logs
mkdir -p /logs

#Default tag v2.5.0-RC1
if [ -z "$1" ]; then
  export PKG_VERSION="v2.5.0-RC1"
else
  export PKG_VERSION="$1"
fi
#Module options need to be passed,otherwise Raise exception
if [ -z "$3" ]; then
 echo "Enter the module name to be build or List of modules to be build\n
 eg :-
      spring-boot-starter_ubuntu_20.04.sh '' '' 'spring-boot-starter-jdbc'
      or
      spring-boot-starter_ubuntu_20.04.sh '' '' 'spring-boot-starter-jdbc spring-boot-starter spring-boot-starter-actuator .....' "
  exit
else
  export MODULElIST="$3"
fi

#For rerunning build spring-boot-starter-v2.5.0-RC1
export FOLDER=$PKG_NAME-$PKG_VERSION
if [ -d ${FOLDER} ] ; then
  echo "Removing existing paths logs, ${FOLDER}  to rerun..."
  rm -rf ${FOLDER}
  rm -rf logs
fi
#Default testing on jdk8
if [ -z "$2" ]; then
  export JDK="openjdk-8-jdk"
else
  export JDK="$2"
fi


#Default installation and dependent packages
sudo apt-get update
sudo apt-get install git wget build-essential unzip build-essential -y


# setup java environment

sudo apt-get install -y ${JDK}
jret=$?
if [ $jret -eq 0 ] ; then
  echo "Sucessfully installed $JDK "
else
  echo "Failed to install $JDK "
  exit
fi

#Setting JAVA_HOME
export folder=`echo ${JDK}  | grep -oP '(?<=openjdk-).*(?=-jdk)'`
export JAVA_HOME=/usr/lib/jvm/java-${folder}-openjdk-ppc64el/
which java
ls /usr/lib/jvm/
# update the path env. variable
export PATH=$PATH:$JAVA_HOME/bin


# install gradle
#export GRADLE_VERSION=6.2.2
export GRADLE_VERSION=7.0.2

wget https://services.gradle.org/distributions/gradle-$GRADLE_VERSION-bin.zip
mkdir -p usr/local/gradle
unzip -d /usr/local/gradle gradle-$GRADLE_VERSION-bin.zip
ls usr/local/gradle/gradle-$GRADLE_VERSION/
rm gradle-$GRADLE_VERSION-bin.zip
export GRADLE_HOME=/usr/local/gradle
# update the path env. variable
export PATH=$PATH:$GRADLE_HOME/gradle-$GRADLE_VERSION/bin

# create folder for saving logs
mkdir -p /logs

# clone, build and test latest version
git clone $REPO $PKG_NAME-$PKG_VERSION
cd $PKG_NAME-$PKG_VERSION/
git checkout -b $PKG_VERSION tags/$PKG_VERSION
gradle wrapper --gradle-version 6.0.1
echo "gradle wrapper done..."
#goto module path to build and test
for MODULE in ${MODULElIST};
do
# Check module path
  cd spring-boot-project/spring-boot-starters/${MODULE}/
  ret=$?
  if [ $ret -eq 0 ] ; then
   echo  "${MODULE} module found in the package to build and started building ..."
  else
   echo  "${MODULE} module not found in the package ..."
   continue
  fi
  #Build and test
  ./../../../gradlew assemble --refresh-dependencies | tee $LOGS_DIRECTORY/$PKG_NAME-$PKG_VERSION-$MODULE-build.log
  ret=$?
  if [ $ret -eq 0 ] ; then
        echo  "Done build for module ${MODULE}......"
  else
        echo  "Failed build for module ${MODULE} ......"
        cd ../../../
        pwd
        continue
  fi
  ./../../../gradlew test | tee $LOGS_DIRECTORY/$PKG_NAME-$PKG_VERSION-$MODULE-test.log
  ret=$?
  if [ $ret -eq 0 ] ; then
        echo  "Done Test for module ${MODULE}......"
  else
        echo  "Failed Test for module ${MODULE}......"
  fi
  cd ../../../
  pwd
done
echo "Completed build for all modules ................\n "
