#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : 
# Version       : 
# Source repo   : 
# Tested on     : 9.3
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : ICH <ich@us.ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME= 
PACKAGE_VERSION= 
PACKAGE_URL= 

yum install -y java-11-openjdk-devel git wget 
export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-11)(?=.*ppc64le)')
export PATH=$JAVA_HOME/bin:$PATH


HOME_DIR=`pwd`

# clone and traverse to package directory
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION


pom_present=(`find . -print | grep pom.xml`)
gradle_present=(`find . -print | grep build.gradle`)

if [ -n "$gradle_present" ];then
        echo "build.gradle Present"

        yum install -y unzip

	#install gradle

        wget https://services.gradle.org/distributions/gradle-7.6.1-bin.zip
        unzip gradle-7.6.1-bin.zip
        mkdir /opt/gradle
        cp -pr gradle-7.6.1/* /opt/gradle
        export PATH=/opt/gradle/bin:${PATH}

        if ! gradle clean build -x test; then
                echo "------------------$PACKAGE_NAME:Install_fails---------------------"
                echo "$PACKAGE_VERSION $PACKAGE_NAME"
                echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails_"
                exit 1
        fi

        if ! gradle test; then
                echo "------------------$PACKAGE_NAME::Install_and_Test_fails-------------------------"
                echo "$PACKAGE_URL $PACKAGE_NAME"
                echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail|  Install _and_Test_fails"
                exit 2
        else
                echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
                echo "$PACKAGE_URL $PACKAGE_NAME"
                echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
                exit 0
        fi
fi


if [ -n "$pom_present" ];then
        echo "pom.xml present"

        #install maven
        wget https://archive.apache.org/dist/maven/maven-3/3.8.1/binaries/apache-maven-3.8.1-bin.tar.gz
        tar -zxf apache-maven-3.8.1-bin.tar.gz
        cp -R apache-maven-3.8.1 /usr/local
        ln -s /usr/local/apache-maven-3.8.1/bin/mvn /usr/bin/mvn
	
	export M2_HOME=/usr/local/maven
	export PATH=$PATH:$M2_HOME/bin

        if ! mvn clean install ; then
                echo "------------------$PACKAGE_NAME:Install_fails---------------------"
                echo "$PACKAGE_VERSION $PACKAGE_NAME"
                echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails_"
                exit 1
        fi

        if ! mvn test ; then
                echo "------------------$PACKAGE_NAME::Install_and_Test_fails-------------------------"
                echo "$PACKAGE_URL $PACKAGE_NAME"
                echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail|  Install _and_Test_fails"
                exit 2
        else
                echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
                echo "$PACKAGE_URL $PACKAGE_NAME"
                echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
                exit 0
        fi

fi
