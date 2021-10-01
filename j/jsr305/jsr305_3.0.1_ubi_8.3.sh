# ---------------------------------------------------------------------
#
# Package       : jar305
# Version       : 3.0.1
# Tested on     : UBI 8.3 (Docker)
# Script License: Apache License, Version 2 or later
# Maintainer    : Sumit Dubey <Sumit.Dubey2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------

#!/bin/bash

#install dependencies
yum install -y wget unzip java-1.8.0-openjdk java-1.8.0-openjdk-devel

#get sources
cd /opt
mkdir jsr305
cd jsr305
wget https://repo1.maven.org/maven2/com/google/code/findbugs/jsr305/3.0.1/jsr305-3.0.1-sources.jar
jar xf jsr305-3.0.1-sources.jar
find -name "*.java" > sources.txt

#build sources
javac @sources.txt
rm -f sources.txt jsr305-3.0.1-sources.jar

#create jar
find . -name "*.java" -type f -delete
jar cvf jsr305-3.0.1.jar javax/
rm -rf META-INF/ javax/

#conclude
echo "/opt/jsr305/jsr305-3.0.1.jar"
echo "Complete!"
