# ----------------------------------------------------------------------------
#
# Package       : geronimo-specs
# Version       : 1.0
# Source repo   : https://github.com/apache/geronimo-specs.git
# Tested on     : RHEL8
# Script License: Apache License, Version 2 or later
# Maintainer    : Narasimha udala<narasimha.rao.udala@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

yum update -y
yum install wget git -y

yum install -y java-1.8.0-openjdk-devel
yum install -y maven

git clone https://github.com/apache/geronimo-specs.git
cd geronimo-servlet_3.0_spec

mvn install -Dskiptests
mvn test
