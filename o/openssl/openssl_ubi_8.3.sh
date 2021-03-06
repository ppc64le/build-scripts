# ----------------------------------------------------------------------------
#
# Package        : openssl
# Version        : openssl-3.0.0-alpha17
# Source repo    : https://github.com/openssl/openssl.git
# Tested on      : ubi:8.3
# Script License : Apache License, Version 2 or later
# Maintainer     : Anant Pednekar <Anant.Pednekar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash
#Update Repos
#yum -y update

#Install Utilities
yum install -y git nano make gcc perl-Test-Simple perl-IPC-Cmd perl-Test-Harness perl-Math-BigInt
yum install -y --nobest  perl-Pod-Html

#Clone repo
tagName=openssl-3.0.0-alpha17
git clone https://github.com/openssl/openssl.git
cd openssl
git checkout tags/$tagName

#Configure for Build
./config
#Build
make
#Install 
make install  
#Test  
make test