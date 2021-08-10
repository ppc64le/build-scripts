# ----------------------------------------------------------------------------
#
# Package       : egeria
# Version       : egeria-release-2.10
# Source repo   : https://github.com/odpi/egeria
# Tested on     : Ubuntu 20.04.1 LTS (Focal Fossa)
# Modules covered : cohort-registry-file-store-connector, data-engine-proxy-connector,data-engine-api,ffdc-services,graph-repository-connector,asset-lineage-api,audit-log-console-connector,audit-log-file-connector,configuration-file-store-connector,connector-configuration-factory,data-engine-proxy-services-server,inmemory-open-metadata-topic-connector,inmemory-repository-connector,ocf-metadata-api,ocf-metadata-client,ocf-metadata-handlers,ocf-metadata-server,open-connector-framework,open-discovery-framework,open-lineage-services-api,open-lineage-services-server,open-metadata-archive-file-connector,open-metadata-conformance-suite-api,open-metadata-conformance-suite-server,open-metadata-security-samples,platform-services-api,ranger-connector,repository-services-apis,repository-services-implementation,rest-client-connectors,rest-client-factory,security-officer-api,security-officer-services-server, security-officer-tag-connector, security-sync-services-server, view-generator-connectors, virtualization-services-api, virtualization-services-server, data-engine-client, metadata-security-apis, metadata-security-connectors,metadata-security-server
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

export URL=https://github.com/odpi/egeria
export BRANCH="$1"
PKG_NAME=${URL##*/}
PKG_NAME=${PKG_NAME%%.*}

if [ -d $PKG_NAME ] ; then
  rm -rf $PKG_NAME
fi

if [ -z "$1" ]; then
  export BRANCH="V2.10"
else
  export BRANCH="$1"
fi

#Default testing on jdk8
if [ -z "$2" ]; then
  export JDK="openjdk-8-jdk"
else
  export JDK="$2"
fi

#Default installation
sudo apt-get update
sudo apt-get install -y apt-utils
sudo apt-get install  git -y

# run tests with java 11 or jdk 8
sudo apt-get install -y ${JDK}
jret=$?
if [ $jret -eq 0 ] ; then
  echo "Sucessfully installed JDK  ${JDK} "
else
  echo "Failed to install JDK  ${JDK} "
  exit
fi

#Setting JAVA_HOME
export folder=`echo ${JDK}  | grep -oP '(?<=openjdk-).*(?=-jdk)'`
export JAVA_HOME=/usr/lib/jvm/java-${folder}-openjdk-ppc64el/

sudo apt install  -y maven


git clone ${URL}
cd $PKG_NAME
git checkout ${BRANCH}
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "${BRANCH} found to checkout"
else
  echo  "${BRANCH} not found"
  exit
fi
# Build and test the package
# BRANCHES can be master, or any other tags supported.
# Ex : egeria-release-2.10 , egeria-release-2.9, master etc
mvn install -B -V
