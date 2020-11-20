# ----------------------------------------------------------------------------
#
# Package       : mongoengine
# Version       : v0.19.1
# Source repo   : https://github.com/MongoEngine/mongoengine
# Tested on     : RHEL 7.6, RHEL 7.7
# Script License: Apache License, Version 2 or later
# Maintainer    : Ryan D'Mello <ryan.dmello1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

export PYTHON=python3
export PIP=pip3
export LANG=en_US.utf8
export PACKAGE_VERSION=v0.19.1
export PACKAGE_NAME=mongoengine
export PACKAGE_URL=https://github.com/MongoEngine/mongoengine
WORK_DIR=`pwd`
mongo_package_name=rh-mongodb36
isinstalled=$(rpm -q $mongo_package_name)
if [ !  "$isinstalled" == "package $mongo_package_name is not installed" ];then
        mkdir -p /data/db
        nohup mongod &
		# Wait for the mongod daemon to setup environment and start the service
        sleep 10m 
        ${PYTHON} setup.py install
        ${PYTHON} setup.py test
else
        yum update -y
        yum install -y yum-utils
        yum-config-manager repos --enable rhel-7-for-power-le-optional-rpms --enable rhel-7-server-for-power-le-rhscl-rpms
        yum install -y python3 python3-pip git zlib-devel libjpeg-turbo libjpeg-turbo-devel gcc gcc-devel gcc-c++ python3-devel libtiff freetype freetype-devel libwebp openjpeg openjpeg2 openjpeg2-devel openjpeg-devel libimagequant libraqm rh-mongodb36

        # Install additional dependencies
        ${PIP} install Pillow littlecms libraqm
        ${PIP} install -r requirements.txt

        git clone ${PACKAGE_URL} ${PACKAGE_NAME} -b ${PACKAGE_VERSION}
        cd ${PACKAGE_NAME}

        scl enable rh-mongodb36 $WORK_DIR/mongoengine_rhel_7.6.sh
fi
