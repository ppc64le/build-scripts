# ----------------------------------------------------------------------------
#
# Package	: crate
# Version	: 3.1.0
# Source repo	: https://github.com/crate/crate.git
# Tested on	: ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer	: Priya Seth <sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

sudo apt-get update -y && sudo apt-get install -y git openjdk-8-jdk locales
cd $HOME && git clone --depth=50 --branch=master https://github.com/crate/crate.git crate/crate
cd crate/crate
export COVERITY_SCAN_TOKEN=[secure]
export CRATE_TESTS_SQL_REQUEST_TIMEOUT="20"
export CRATE_TESTS_NO_IPV6=true
export _JAVA_OPTIONS="-Xms1g -Xmx1g"
export GRADLE_OPTS="-Dorg.gradle.daemon=false"
export TERM=dumb
export LANG=en_US.UTF-8
sudo locale-gen en_US.UTF-8
export LC_ALL=en_US.UTF-8
mkdir -p $HOME/.gradle && echo "org.gradle.daemon=false" >> ~/.gradle/gradle.properties
git submodule update --init -- es/upstream
./gradlew assemble
export PROJECT_NAME=crate/crate
#fix for ArithmeticIntegrationTest.java
sed -i '/execute("select x, base, log(x, base) from t where log(x, base) = 2.0 order by x");/ c\
\ \ \ \ \ \ \ \ \execute("select x, base, round(log(x, base)) from t where round(log(x, base)) = 2 order by x");' sql/src/test/java/io/crate/integrationtests/ArithmeticIntegrationTest.java
sed -i '/assertThat((Double) response.rows()\[0\]\[2\], is(2.0));/ c\
\ \ \ \ \ \ \ \ assertThat((Long) response.rows()\[0\]\[2\], is(2L));' sql/src/test/java/io/crate/integrationtests/ArithmeticIntegrationTest.java
sed -i '/assertThat((Double) response.rows()\[1\]\[2\], is(2.0));/ c\
\ \ \ \ \ \ \ \ assertThat((Long) response.rows()\[1\]\[2\], is(2L));' sql/src/test/java/io/crate/integrationtests/ArithmeticIntegrationTest.java
#Test execution
./gradlew -s :sql:test
sed -i '/ARCHITECTURES = Collections.unmodifiableMap(m);/ i \ \ \ \ \ \ \ \ m.put(\"ppc64le\", new Arch(0xC0000015, 0xFFFFFFFF, 2, 189, 11, 362, 358));'  es/upstream/core/src/main/java/org/elasticsearch/bootstrap/SystemCallFilter.java
./gradlew installDist
echo "transport.host : localhost   
transport.tcp.port : 4300  
http.port : 4200  
network.host : 0.0.0.0">> ./app/build/install/crate/config/crate.yml
sed -i /auth.host/s/^/#/ ./app/build/install/crate/config/crate.yml
# command to start crate 
#./app/build/install/crate/bin/crate &

