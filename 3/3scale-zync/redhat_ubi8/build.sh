# ----------------------------------------------------------------------------
# Package       : zync
# Version       : master
# Source repo   : https://github.com/3scale/zync
# Tested on     : RHEL_8.3
# Script License: Apache License, Version 2 or later
# Maintainer    : Abhijit Mane <abhijman@in.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given platform using
#             the mentioned version of the package. It may not work as expected 
#             with newer versions of the package and/or distribution.
#             In such case, please contact "Maintainer" of this script.
# ----------------------------------------------------------------------------


#!/bin/bash

# clone branch/release passed as argument, if none, use master
if [ -z $1 ] || [ "$1" == "lasttestedrelease" ]
then
	BRANCH=""
else
	BRANCH="--branch $1"
fi

if [ "$BRANCH" == "" ]
then
	echo "BRANCH = master"
else
	echo "BRANCH = $BRANCH"
fi

git clone $BRANCH https://github.com/3scale/zync || (echo "git clone failed"; exit $?)
cd zync

export PGDATA=$PWD/pgsql/data
mkdir -p $PGDATA
export PATH=$PATH:/usr/pgsql-13/bin:/usr/local/bin

pg_ctl initdb -D $PGDATA -o "-E=UTF8"
pg_ctl start -D $PGDATA
bundle config set --local path 'vendor/bundle'


######## needed only for below releases:
#BRANCH=3scale-2.10.0-GA
#BRANCH=3scale-2.9.1-GA

# This update is needed before install
# gem install mimemagic -v 0.3.10
# bundle update mimemagic

# Change "mimemagic (0.3.5)" to "mimemagic (0.3.10) in zync/Gemfile.lock
############################


# install & setup
bundle install
./bin/setup

# run tests if "runtest" is passed as argument
if [ "$2" == "runtest" ]
then
	bundle exec rails test
fi

# copy
cp -r vendor/bundle ../

# cleanup
cd ..
rm -rf zync
