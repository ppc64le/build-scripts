# ----------------------------------------------------------------------------
#
# Package	: Java Simple Argument Parser
# Version	: 2.1
# Source repo	: https://sourceforge.net/projects/jsap/files/jsap/2.1/
# Tested on	: rhel_7.4
# Script License: Apache License, Version 2 or later
# Maintainer	: Yugandha Deshpande <yugandha@us.ibm.com>
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
sudo yum install -y wget ant ant-junit junit
wget https://sourceforge.net/projects/jsap/files/jsap/2.1/JSAP-2.1-src.tar.gz
tar -zxvf JSAP-2.1-src.tar.gz 
rm -rf JSAP-2.1-src.tar.gz
cd JSAP-2.1
ant compile-all
ant test
