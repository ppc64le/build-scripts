# ----------------------------------------------------------------------------
#
# Package       : Jpmml Model
# Version       : 1.3.9
# Source repo   : https://github.com/jpmml/jpmml-model
# Tested on     : Ubuntu 16.04
# Language      : Java
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer    : Meghali Dhoble <dhoblem@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#! /bin/bash
sudo apt-get update -y
sudo apt-get install -y git wget tar openjdk-8-jdk maven

# set the PATH to access Maven and Java
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el
export PATH=$PATH:$JAVA_HOME/bin

git clone https://github.com/jpmml/jpmml-model && cd jpmml-model
mvn clean install

