# ----------------------------------------------------------------------------
#
# Package       : ICU4j
# Version       : 60.2
# Source repo   : http://source.icu-project.org/repos/icu/tags/release-60-2/icu4j
# Tested on     : rhel_7.3
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

#!/bin/bash
# Install dependencies
sudo yum update -y
sudo yum install -y subversion ant ant-junit java-1.8.0-openjdk

# Setup environment
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$JAVA_HOME/bin:$PATH

# Download source
svn export http://source.icu-project.org/repos/icu/tags/release-60-2/icu4j/ icu4j
cd icu4j

# Build and Test
sudo ant && sudo ant check
