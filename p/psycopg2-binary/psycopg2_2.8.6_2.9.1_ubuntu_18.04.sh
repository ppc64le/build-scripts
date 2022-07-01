#!/bin/bash -e
# ------------------------------------------------------------------------------------------------
#
# Package         : psycopg2-binary
# Version         : 2.8.6, 2.9.1
# Source repo     : https://github.com/psycopg/psycopg2.git
# Tested on       : Ubuntu 18.04 (Docker)
# Language        : Python
# Travis-Check    : True
# Script License  : Apache License, Version 2 or later
# Maintainer      : Sumit Dubey <Sumit.Dubey2@ibm.com>
# Instructions	  : 1. Run the docker conatiner as: 
#		  docker run -t -d --privileged docker.io/ppc64le/ubuntu:18.04
#		  If the docker container is already running remove the script code under...
#		  #Install postgres and run tests
#		  2. Connect to the docker container
#		  docker exec -it <container id> bash
#		  3. Run this script
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ------------------------------------------------------------------------------------------------

#Variables
PACKAGE_NAME=psycopg2
PACKAGE_URL=https://github.com/psycopg/psycopg2.git
PACKAGE_VERSION=2_8_6

echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional paramater whose default value is 2_8_6 for 2.8.6"

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

#Install required packages
apt-get update -y
apt-get install -y wget sudo python3-dev libpq-dev git build-essential python3-setuptools lsb-release 

#Clone and checkout the package
cd /opt
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Build and install package
python3 setup.py install

#Install postgres and run tests
sudo apt-get install ca-certificates -y
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'
TZ=Europe/Minsk
ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
apt-get update -y
apt-get install postgresql postgresql-contrib -y
service postgresql start
sudo -u postgres -i bash << EOF
psql -c "CREATE DATABASE psycopg2_test;"
cd /opt/psycopg2/
python3 -c "import tests; tests.unittest.main(defaultTest='tests.test_suite')" --verbose
echo "Installation and tests complete."
EOF