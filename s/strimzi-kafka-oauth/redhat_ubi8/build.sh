# ----------------------------------------------------------------------------
#
# Package       : strimzi-kafka-oauth
# Version       : master (default)
# Source repo   : https://github.com/strimzi/strimzi-kafka-oauth
# Tested on     : RHEL_8
# Script License: Apache License, Version 2 or later
# Maintainer    : Amir Sanjar <amir.sanjar@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash
if [ -z $1 ] 
then
	# Master branch
	BRANCH=""
else
	BRANCH="--branch "$1
fi
BUILD_DIR="strimzi-kafka-oauth"
## Exit if git operation failed
git clone $BRANCH https://github.com/strimzi/strimzi-kafka-oauth.git $BUILD_DIR || exit "$?"

cd $BUILD_DIR
# Exit if build or test failed
mvn clean install || exit "$?"
cd ..

# zip output artifacts
tar cfz $BUILD_DIR.tar.gz $(ls $BUILD_DIR/oauth-common/target/kafka-oauth-common-*.jar $BUILD_DIR/oauth-server/target/kafka-oauth-server-*.jar $BUILD_DIR/oauth-server-plain/target/kafka-oauth-server-plain-*.jar $BUILD_DIR/oauth-keycloak-authorizer/target/kafka-oauth-keycloak-authorizer-*.jar $BUILD_DIR/oauth-client/target/kafka-oauth-client-*.jar $BUILD_DIR/oauth-common/target/lib/keycloak-common-*.jar $BUILD_DIR/oauth-common/target/lib/keycloak-core-*.jar $BUILD_DIR/oauth-common/target/lib/bcprov-*.jar )

tar cfz custom_claim.tar.gz $(ls $BUILD_DIR/oauth-server/target/lib/json-path-*.jar $BUILD_DIR/oauth-server/target/lib/json-smart-*.jar $BUILD_DIR/oauth-server/target/lib/accessorts-smart-*.jar )

rm -rf $BUILD_DIR

echo "strimzi-kafka-oauth.tar.gz contains following jar files:"
tar tvf strimzi-kafka-oauth.tar.gz

## just in master
if [ -f "custom_claim.tar.gz" ]; then
	echo "custom_claim.tar.gz contains following jar files:"
	tar tvf custom_claim.tar.gz
fi
