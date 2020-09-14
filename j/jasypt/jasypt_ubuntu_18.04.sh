# ----------------------------------------------------------------------------
#
# Package	: jasypt
# Version	: 1.9.3
# Source repo	: https://svn.code.sf.net/p/jasypt/code/trunk
# Tested on	: ubuntu_18.04
# Script License: Apache License, Version 2 or later
# Maintainer	: Atul Sowani <sowania@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

# Install dependencies.
sudo apt-get update -y
sudo apt-get install -y subversion maven openjdk-8-jdk openjdk-8-jre
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-ppc64el
export PATH=$JAVA_HOME/bin:$PATH

# Clone and build source.
svn checkout https://svn.code.sf.net/p/jasypt/code/trunk jasypt
cd jasypt/jasypt
mvn test
mvn clean:clean install
