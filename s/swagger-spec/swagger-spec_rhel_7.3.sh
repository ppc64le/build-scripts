# ----------------------------------------------------------------------------
#
# Package	: swagger-spec
# Version	: 3.0.0-rc2
# Source repo	: https://github.com/swagger-api/swagger-spec.git
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
curl https://bintray.com/sbt/rpm/rpm | sudo tee /etc/yum.repos.d/bintray-sbt-rpm.repo
sudo yum update -y
sudo yum install -y wget tar gzip sbt git java-1.7.0-openjdk-devel.ppc64le
export JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF-8"

# Clone and build source code.
git clone --depth=50 --branch=master https://github.com/swagger-api/swagger-spec.git
cd swagger-spec
sbt compile
sbt test
