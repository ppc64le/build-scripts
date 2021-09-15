# ----------------------------------------------------------------------------
#
# Package       : jacoco ant
# Version       : 0.8.7
# Source repo   : https://github.com/jacoco/jacoco.git
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
git clone https://github.com/jacoco/jacoco.git
cd jacoco/ org.jacoco.ant

mvn insatall