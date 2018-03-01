# ----------------------------------------------------------------------------
#
# Package       : Apache Freemarker
# Version       : 2.3.gae
# Source repo   : https://github.com/apache/incubator-freemarker
# Tested on     : rhel_7.4
# Script License: Apache License, Version 2 or later
# Maintainer    : Yugandha Deshpande <yugandha@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

sudo yum -y update
sudo yum -y install java-1.8.0-openjdk-devel.ppc64le ant ant-junit \
    apache-ivy apache-commons-lang git
git clone https://github.com/apache/incubator-freemarker
cd incubator-freemarker
ant download-ivy
sudo cp /usr/share/java/ivy.jar /usr/share/ant/lib
ant update-deps
sudo cp /usr/share/java/commons-lang.jar /incubator-freemarker/.ivy/repo/commons-lang/commons-lang/commons-lang-2.3.jar
sudo ant
sudo ant test
