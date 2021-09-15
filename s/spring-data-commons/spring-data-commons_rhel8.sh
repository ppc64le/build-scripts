# ----------------------------------------------------------------------------
#
# Package       : spring-data-commons
# Version       : v2.5.4
# Source repo   : https://github.com/spring-projects/spring-data-commons.git
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
yum install git maven -y
yum install java-1.8.0-openjdk-devel
git clone https://github.com/spring-projects/spring-data-commons.git
cd spring-data-commons
./mvnw clean install