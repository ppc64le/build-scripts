#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : junit4
# Version       : r4.13.2
# Source repo   : https://github.com/junit-team/junit4.git
# Tested on     : UBI 9.3
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Siddesh Sangodkar <siddesh.sangodkar1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


set -e

# variables
PACKAGE_NAME=junit4
PACKAGE_URL=https://github.com/junit-team/junit4.git
PACKAGE_VERSION=${1:-r4.13.2}

# install tools and dependent packages
#yum -y update
yum install -y git wget 
yum install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel java-1.8.0-openjdk-headless gcc-c++ jq cmake ncurses unzip make  gcc-gfortran

# setup java environment
export JAVA_HOME=$(compgen -G '/usr/lib/jvm/jre-1.8.0-openjdk-*')

# update the path env. variable 
export PATH="$JAVA_HOME/bin/":$PATH
useradd -G root -d /home/testuser testuser -p test123
cd /home/testuser
chown -R  testuser /home/testuser

yum install -y wget git patch sudo

# clone, build and test specified version
java -version


#clone package
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

cat > settings.xml << EOF
<settings>
    <mirrors xmlns="http://maven.apache.org/SETTINGS/1.1.0">
        <mirror>
            <mirrorOf>central</mirrorOf>
            <name>GCS Maven Central mirror</name>
            <url>https://maven-central.storage-download.googleapis.com/maven2/</url>
            <id>google-maven-central</id>
        </mirror>
    </mirrors>
</settings>

EOF

#Build

# # install maven
wget https://archive.apache.org/dist/maven/maven-3/3.8.6/binaries/apache-maven-3.8.6-bin.tar.gz
tar -xvzf apache-maven-3.8.6-bin.tar.gz
cp -R apache-maven-3.8.6 /usr/local
ln -s /usr/local/apache-maven-3.8.6/bin/mvn /usr/bin/mvn
export M2_HOME=/usr/local/maven
# update the path env. variable 
export PATH=$PATH:$M2_HOME/bin
chown testuser -R /home/testuser

if ! su -p testuser -c 'mvn verify javadoc:javadoc site:site --batch-mode --errors --settings settings.xml'; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi 

exit 0
