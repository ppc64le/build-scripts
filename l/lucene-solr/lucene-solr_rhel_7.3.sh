# ----------------------------------------------------------------------------
#
# Package	: lucene-solr
# Version	: 6.5.1
# Source repo	: http://git.apache.org/lucene-solr.git
# Tested on	: rhel_7.3
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
sudo yum update -y
sudo yum install -y git ant gcc wget java-1.8.0-openjdk-devel.ppc64le tar

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$JAVA_HOME/bin:$PATH
export ANT_HOME=/usr/share/ant

wget http://archive.apache.org/dist/ant/binaries/apache-ant-1.9.6-bin.tar.gz
tar -xvzf apache-ant-1.9.6-bin.tar.gz
sudo cp apache-ant-1.9.6/lib/*.jar $ANT_HOME/lib

cd
git clone https://git-wip-us.apache.org/repos/asf/ant-ivy.git
cd ant-ivy
ant jar
sudo ant install

# Clone source code and build.
cd
git clone http://git.apache.org/lucene-solr.git
cd lucene-solr && ant ivy-bootstrap && ant --noconfig compile
