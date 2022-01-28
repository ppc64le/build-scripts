# ----------------------------------------------------------------------------
#
# Package       :  ST4
# Version       :  st-4.0.7
# Source repo   :  https://github.com/antlr/stringtemplate4.git
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
export REPO=https://github.com/antlr/stringtemplate4.git

#Default tag Generex
if [ -z "$1" ]; then
  export VERSION="st-4.0.7"
else
  export VERSION="$1"
fi

yum update -y
yum install git maven -y
git clone ${REPO}
cd stringtemplate4
git checkout ${VERSION}
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "${VERSION} found to checkout"
else
  echo  "${VERSION} not found"
  exit
fi
mvn compile
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "Done Complie ......"
else
  echo  "Failed Test ......"
fi