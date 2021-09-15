# ----------------------------------------------------------------------------
#
# Package       : highlight.js
# Version       : 11.2.0
# Source repo   : https://github.com/highlightjs/highlight.js.git
# Tested on     : RHEL8
# Script License: Apache License, Version 2 or later
# Maintainer    : Narasimha udala <narasimha.rao.udala@ibm.com>
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
yum install git -y
dnf module install nodejs:14 
#Error: Cannot find module 'commander'
npm install commander --save

git clone https://github.com/highlightjs/highlight.js.git
cd /highlight.js

npm run build
npm run test





