# ----------------------------------------------------------------------------
#
# Package       : kafka
# Version       : 1.1.1, 2.2.0, 2.2.1-rc1
# Source repo   : https://github.com/apache/kafka
# Tested on     : rhel_7.4
# Script License: Apache License, Version 2 or later
# Maintainer    : Priya Seth <sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

if [ "$#" -gt 0 ]
then
    VERSION=$1
else
    VERSION="2.2.0"
fi

#Install dependencies
sudo yum update -y
sudo yum install -y git wget unzip java-1.8.0-openjdk java-1.8.0-openjdk-devel

cd $HOME
wget https://services.gradle.org/distributions/gradle-4.8-bin.zip
unzip gradle-4.8-bin.zip

#Set required environment variables
export PATH=$HOME/gradle-4.8/bin:$PATH

#Build and run unit tests
cd $HOME
git clone https://github.com/apache/kafka
cd kafka
git checkout ${VERSION}


#Note: Downgrading snappy version as version 1.1.7.2 links to GLIBC 2.2, and hence 
#does not work on RHEL where we have an older version of GLIBC
#sed -i 's/  snappy: "1.1.7.1",/  snappy: "1.1.4",/g' gradle/dependencies.gradle
sed -i 's/  snappy: "1.1.7.2",/  snappy: "1.1.4",/g' gradle/dependencies.gradle

gradle clean
gradle
./gradlew jar
./gradlew releaseTarGz -x signArchives

#Please uncomment below line if you want to to execute unit tests
#Results are "5031 tests completed, 1 failed, 1 skipped"
#./gradlew unitTest
