#!/bin/sh
# Package       : angular-toaster
# Version       : 1.2.0
# Source repo   : https://github.com/jirikavi/AngularJS-Toaster 
# Tested on     : UBI 8.4
# Script License: Apache License, Version 2 or later
# Maintainer    : Ankit Paraskar <ankit.paraskar@ibm.com
# Language      : Node
# Travis-Check  : True 
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=angular-toaster
PACKAGE_VERSION=1.2.0
PACKAGE_URL=https://github.com/jirikavi/AngularJS-Toaster

yum -y update && yum install -y yum-utils nodejs nodejs-devel nodejs-packaging npm python38 python38-devel ncurses git gcc gcc-c++ libffi libffi-devel ncurses git jq make cmake npm

yum install npm -y

npm install n -g && n latest && npm install -g npm@latest && export PATH="$PATH" && npm install --global yarn grunt-bump xo testem acorn

mkdir -p /home/tester/output
cd /home/tester

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

yum install -y npm
npm install --save angularjs-toaster


