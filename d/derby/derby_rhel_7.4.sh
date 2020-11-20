# ----------------------------------------------------------------------------
#
# Package	: derby
# Version	: 10.14.1.0
# Source repo	: https://github.com/apache/derby.git
# Tested on	: rhel_7.4
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
sudo yum install -y git ant java-1.8.0-openjdk java-1.8.0-openjdk-devel

# Clone and build source.
git clone https://github.com/apache/derby.git
cd derby
git checkout 10.14.1.0
ant -quiet clobber
ant -quiet buildsource
ant -quiet buildjars
java -jar jars/sane/derbyrun.jar sysinfo
