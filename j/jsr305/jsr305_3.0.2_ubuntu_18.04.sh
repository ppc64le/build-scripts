#!/bin/bash -e
# ----------------------------------------------------------------------------------------------------
#
# Package       : jar305
# Version       : 3.0.2
# Source repo	: https://repo1.maven.org/maven2/com/google/code/findbugs/jsr305/3.0.2/jsr305-3.0.2-sources.jar
# Tested on     : ubuntu_18.04 (Docker)
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Manik Fulpagar <Manik_Fulpagar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------------------------------

set -ex

#Variables
PACKAGE_NAME=jar305
PACKAGE_VERSION=3.0.2
PACKAGE_URL=https://repo1.maven.org/maven2/com/google/code/findbugs/jsr305/3.0.2/jsr305-3.0.2-sources.jar

#install dependencies
apt update && apt install -y wget unzip openjdk-8-jdk openjdk-8-jre

#get sources
cd /opt
mkdir jsr305
cd jsr305
wget https://repo1.maven.org/maven2/com/google/code/findbugs/jsr305/3.0.2/jsr305-3.0.2-sources.jar
jar xf jsr305-3.0.2-sources.jar
find -name "*.java" > sources.txt

#build sources
javac @sources.txt
rm -f sources.txt jsr305-3.0.2-sources.jar

#create jar
find . -name "*.java" -type f -delete
jar cvf jsr305-3.0.2.jar javax/
rm -rf META-INF/ javax/

#conclude
echo "/opt/jsr305/jsr305-3.0.2.jar"
echo "Complete!"