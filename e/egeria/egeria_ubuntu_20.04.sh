# ----------------------------------------------------------------------------
#
# Package       : egeria
# Version       : egeria-release-2.10 
# Source repo   : https://github.com/odpi/egeria
# Tested on     : Ubuntu 20.04.1 LTS (Focal Fossa)
# Modlues covered : cohort-registry-file-store-connector, data-engine-proxy-connector,data-engine-api,ffdc-services,graph-repository-connector,asset-lineage-api,audit-log-console-connector,audit-log-file-connector,configuration-file-store-connector,connector-configuration-factory,data-engine-proxy-services-server,inmemory-open-metadata-topic-connector,inmemory-repository-connector,ocf-metadata-api,ocf-metadata-client,ocf-metadata-handlers,ocf-metadata-server,open-connector-framework,open-discovery-framework,open-lineage-services-api,open-lineage-services-server,open-metadata-archive-file-connector,open-metadata-conformance-suite-api,open-metadata-conformance-suite-server,open-metadata-security-samples,platform-services-api,ranger-connector,repository-services-apis,repository-services-implementation,rest-client-connectors,rest-client-factory,security-officer-api,security-officer-services-server, security-officer-tag-connector, security-sync-services-server, view-generator-connectors, virtualization-services-api, virtualization-services-server, data-engine-client
# Script License: Apache License, Version 2 or later
# Maintainer    : Nagesh Tarale <Nagesh.Tarale@ibm.com> / Priya Seth<sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

export URL=https://github.com/odpi/egeria.git
export BRANCH="$1"
PKG_NAME=${URL##*/}
PKG_NAME=${PKG_NAME%%.*}

if [ -d $PKG_NAME ] ; then
  rm -rf $PKG_NAME
fi
# Verify the arguments passed from command line.

if [ $# -lt 1 ]
then
  echo "Usage: $0 branch or tag_name >> For specific versions, default is master"
  BRANCH="master"
fi
#echo "Branch is $1 and no of arguments $# "
if [ $# -gt 1 ]
then
        echo "USAGE: $0 BRANCH"
        exit 0
else
        echo "Cloning the target"
fi

# Build and test the package
# BRANCHES can be master, or any other tags supported.
# Ex : egeria-release-2.10 , egeria-release-2.9, master etc
git clone --depth 1 --branch $BRANCH $URL --single-branch
cd $PKG_NAME
sudo mvn install -B -V   
