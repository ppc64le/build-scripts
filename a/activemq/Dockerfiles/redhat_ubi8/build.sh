# ----------------------------------------------------------------------------
#
# Package       : activemq 
# Version       : 5.17.1
# Source repo   : https://github.com/apache/activemq
# Tested on     : RHEL_8
# Script License: Apache License, Version 2 or later
# Maintainer    : Amir Sanjar <amir.sanjar@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash
git clone https://github.com/apache/activemq 
cd activemq 
mvn clean install -DskipTests=true
cp assembly/target/apache-activemq-*-bin.zip ../
cd ..
rm -rf activemq

