# ----------------------------------------------------------------------------
#
# Package	: lucene-solr
# Version	: 6.5.1
# Source repo	: http://git.apache.org/lucene-solr.git
# Tested on	: ubuntu_16.04
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
sudo apt-get install -y build-essential g++ software-properties-common \
    wget ant openjdk-8-jdk openjdk-8-jre git
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el
export PATH=$PATH:$JAVA_HOME/bin

cd
git clone https://git-wip-us.apache.org/repos/asf/ant-ivy.git
cd ant-ivy
ant jar
sudo ant install

# Clone source code and build.
cd
git clone http://git.apache.org/lucene-solr.git
cd lucene-solr && ant ivy-bootstrap && ant compile
