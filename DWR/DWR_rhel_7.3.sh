# ----------------------------------------------------------------------------
#
# Package	: DWR
# Version	: 3.0.2
# Source repo	: https://svn.directwebremoting.org/dwr/trunk
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
sudo yum install -y ant ant-junit subversion java-1.7.0-openjdk-devel.ppc64le

# Setting JAVA_HOME which will be used to compile DWR code
export JAVA_HOME="/usr/lib/jvm/java-1.7.0-openjdk"
export JAVA_TOOL_OPTIONS="-Dfile.encoding=ISO-8859-1"

# Create DWR jar on rhel
svn co http://svn.directwebremoting.org/dwr/trunk dwr
cd dwr && ant jar
