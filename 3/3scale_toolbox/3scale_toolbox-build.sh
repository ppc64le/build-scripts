# --------------------------------------------------------------------------------
# Package       : 3scale_toolbox 
# Version       : v0.18.1
# Source repo   : https://github.com/3scale/3scale_toolbox
# Tested on     : RHEL_8.3
# Script License: Apache License, Version 2 or later
# Maintainer    : Abhijit Mane <abhijman@in.ibm.com>
# Language 		: Go
# Ci-Check  : False
# Disclaimer: This script has been tested in non-root mode on given platform using
#             the mentioned version of the package. It may not work as expected 
#             with newer versions of the package and/or distribution.
#             In such case, please contact "Maintainer" of this script.
# --------------------------------------------------------------------------------

#!/bin/bash

# clone branch/release passed as argument, if none, use last stable release
if [ -z $1 ] || [ "$1" == "laststablerelease" ]
then
	RELEASE_TAG=v0.18.1
else
	RELEASE_TAG=$1
fi

echo "RELEASE_TAG = $RELEASE_TAG"

git clone -b $RELEASE_TAG https://github.com/3scale/3scale_toolbox
cd 3scale_toolbox

# vendor/bundle install
bundle config set --local path 'vendor/bundle'
bundle install --jobs=3 --retry=3

# Rake install
bundle exec rake install

# run tests if "runtest" is passed as argument
if [ "$2" == "runtest" ]
then
	# Unit-tests
	bundle exec rake spec:unit

	# Populate .env for Integration tests
	echo "ENDPOINT=https://autotest-admin.3scale.net/" >> .env
	echo "PROVIDER_KEY=dc6ecfa9d8eb9658a2082ef796d6cee4299fd1b57fe605d5fa5082722961c9dd" >> .env
	echo "VERIFY_SSL=false" >> .env

	# Trigger Integration Tests
	bundle exec rake spec:integration
fi

# copy binaries
cp exe/3scale ../

# cleanup
cd ..
rm -rf 3scale_toolbox
