# ----------------------------------------------------------------------------
#
# Package	: GNU Trove
# Version	: 3.0.3
# Source repo	: https://bitbucket.org/trove4j/trove/downloads/trove-3.1a1.tar.gz
# Tested on	: rhel_7.4
# Script License: Apache License, Version 2 or later
# Maintainer	: Yugandha Deshpande <yugandha@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

sudo yum -y update
sudo yum -y install ant-junit junit wget java-1.8.0-openjdk-devel.ppc64le ant
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
wget https://bitbucket.org/trove4j/trove/downloads/trove-3.0.3.tar.gz
tar -zxvf trove-3.0.3.tar.gz
rm -rf trove-3.0.3.tar.gz
cd 3.0.3
ant
ant test
