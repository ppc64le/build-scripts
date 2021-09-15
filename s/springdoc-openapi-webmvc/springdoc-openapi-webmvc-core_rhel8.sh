# ----------------------------------------------------------------------------
#
# Package       : springdoc-openapi-webmvc-core
# Version       : v1.5.10
# Source repo   : https://github.com/springdoc/springdoc-openapi.git
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

git clone https://github.com/springdoc/springdoc-openapi.git

cd /springdoc-openapi/springdoc-openapi-webmvc-core
mvn clean install