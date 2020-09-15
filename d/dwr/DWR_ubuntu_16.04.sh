# ----------------------------------------------------------------------------
#
# Package	: DWR
# Version	: 3.0.2
# Source repo	: https://svn.directwebremoting.org/dwr/trunk
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

sudo apt-get update
sudo apt-get install -y ant subversion openjdk-8-jdk

export JAVA_TOOL_OPTIONS=-Dfile.encoding=ISO-8859-1
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el

svn co https://svn.directwebremoting.org/dwr/trunk dwr
cd dwr && ant jar
