
# ----------------------------------------------------------------------------
#
# Package       : de.flapdoodle.embed.mongo
# Version       : 2.2.1-SNAPSHOT
# Source repo   : https://github.com/flapdoodle-oss/de.flapdoodle.embed.mongo
# Tested on     : rhel_7.6
# Script License: Apache License, Version 2 or later
# Maintainer    : Amit Shirodkar <amit.shirodkar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash


export CWD=`pwd`

yum install -y git vim java-1.8.0-openjdk-devel.ppc64le wget net-snmp-libs.ppc64le net-snmp-agent-libs.ppc64le

cd /opt/
wget https://archive.apache.org/dist/maven/maven-3/3.6.2/binaries/apache-maven-3.6.2-bin.tar.gz
tar -xvzf apache-maven-3.6.2-bin.tar.gz
export PATH=/opt/apache-maven-3.6.2/bin/:$PATH

cd $CWD

git clone https://github.com/flapdoodle-oss/de.flapdoodle.embed.process.git
cd de.flapdoodle.embed.process
git checkout de.flapdoodle.embed.process-2.1.2 && git apply ../de.flapdoodle.embed.process.patch
mvn clean install -DskipTests

#Download enterprise edition mongodb in /opt/
#create symbolic links

cd $CWD
git clone https://github.com/flapdoodle-oss/de.flapdoodle.embed.mongo.git
cd de.flapdoodle.embed.mongo
git checkout 4e9ffbe26f02d0560d8d9e4ab73f3aca0f399681 && git apply ../de.flapdoodle.embed.mongo.patch
mvn clean install -DskipTests


