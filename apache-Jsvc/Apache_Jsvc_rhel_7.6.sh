# ----------------------------------------------------------------------------
#
# Package	: Apache Jsvc
# Version	: latest (1.2.3)
# Source repo	: https://github.com/apache/commons-daemon/tree/master/src/native/unix
# Tested on	: rhel_7.6
# Script License: Apache License, Version 2
# Maintainer	: Vrushali Inamdar <vrushali.inamdar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

git clone https://github.com/apache/commons-daemon.git
cd commons-daemon

wrkdir=`pwd`

# set JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-1.8.0

# Build commons-daemon JAR file from source code on Power
cd $wrkdir
mvn clean install

# Make sure commons-daemon-*.jar file is generated under target directory
ls target/commons-daemon-*.jar

# Run all the tests
mvn clean verify

# ---- Build Apache Jsvc from source -----
echo "Installing dependencies required for Jsvc ..."

# To build under a UNIX operating system you will need:

#	GNU AutoConf (at least version 2.53)
#	An ANSI-C compliant compiler (GCC is good)
#	GNU Make
#	A Java Platform 2 compliant SDK
# NOTE::GNU make is provided by the devtoolset-7-make package and is automatically installed with devtoolset-7-toolchain 
# Install the required dependencies
yum install -y gcc autoconf automake devtoolset-7-make
echo "Done"
echo "Building jsvc binary from source .. "
cd $wrkdir/src/native/unix
sh support/buildconf.sh
echo "Built 'configure' program ... "

# # Save the path to PhantomJS binary
phantomjs_binary_path=$wrkdir/phantomjs/bin
echo "# # #$phantomjs_binary_path"
./configure
make
echo "Generated the executable file jsvc .. "

echo "Verifying jsvc binary ..."
./jsvc -help

echo "Jsvc built successfully !"

# The generated jsvc binary can be validated by implementing a src/samples/SimpleDaemon 
# Refer https://github.com/apache/commons-daemon/tree/master/src/samples/README.txt to build the samples and execute them using 'jsvc' binary

