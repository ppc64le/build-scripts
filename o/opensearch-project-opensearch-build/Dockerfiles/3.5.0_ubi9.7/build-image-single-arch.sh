#!/bin/bash

# Copyright OpenSearch Contributors
# SPDX-License-Identifier: Apache-2.0
#
# The OpenSearch Contributors require contributions made to
# this file be licensed under the Apache-2.0 license or a
# compatible open source license.

# This script is to automate the docker image creation process of OpenSearch and OpenSearch-Dashboards

set -e

# Import libs
. ../../lib/shell/file_management.sh

function usage() {
    echo ""
    echo "This script is used to build the OpenSearch Docker image with single architecture (x64 or arm64). It prepares the files required by the Dockerfile in a temporary directory, then builds and tags the Docker image."
    echo "--------------------------------------------------------------------------"
    echo "Usage: $0 [args]"
    echo ""
    echo "Required arguments:"
    echo -e "-v VERSION\tSpecify the OpenSearch version number that you are building, e.g. '1.0.0' or '1.0.0-beta1'. This will be used to label the Docker image. If you do not use the '-o' option then this tool will download a public OPENSEARCH release matching this version."
    echo -e "-f DOCKERFILE\tSpecify the dockerfile full path, e.g. dockerfile/opensearch.al2.dockerfile."
    echo -e "-p PRODUCT\tSpecify the product, e.g. opensearch or opensearch-dashboards, make sure this is the name of your config folder and the name of your .tgz defined in dockerfile."
    echo -e "-a ARCHITECTURE\tSpecify one and only one architecture, e.g. x64 or arm64."
    echo ""
    echo "Optional arguments:"
    echo -e "-t TARBALL\tSpecify a local opensearch or opensearch-dashboards tarball. You still need to specify the version - this tool does not attempt to parse the filename."
    echo -e "-n NOTES\tSpecify Pipeline Notes of the run, defaults to None."
    echo -e "-h\t\tPrint this message."
    echo "--------------------------------------------------------------------------"
}

while getopts ":ht:n:v:f:p:a:" arg; do
    case $arg in
        h)
            usage
            exit 1
            ;;
        t)
            TARBALL=`realpath $OPTARG`
            ;;
        n)
            NOTES=$OPTARG
            ;;
        v)
            VERSION=$OPTARG
            ;;
        f)
            DOCKERFILE=$OPTARG
            ;;
        p)
            PRODUCT=$OPTARG
            ;;
        a)
            ARCHITECTURE=$OPTARG
            ;;
        :)
            echo "-${OPTARG} requires an argument"
            usage
            exit 1
            ;;
        ?)
            echo "Invalid option: -${OPTARG}"
            exit 1
            ;;
    esac
done

# Validate the required parameters to present
if [ -z "$VERSION" ] || [ -z "$DOCKERFILE" ] || [ -z "$PRODUCT" ] || [ -z "$ARCHITECTURE" ]; then
  echo "You must specify '-v VERSION', '-f DOCKERFILE', '-p PRODUCT', '-a ARCHITECTURE'"
  usage
  exit 1
else
  echo $VERSION $DOCKERFILE $PRODUCT $ARCHITECTURE
fi

if [ "$PRODUCT" != "opensearch" ] && [ "$PRODUCT" != "opensearch-dashboards" ]
then
    echo "Enter either 'opensearch' or 'opensearch-dashboards' as product name for -p parameter"
    exit 1
else
    PRODUCT_ALT=`echo $PRODUCT | sed 's@-@_@g'`
    echo $PRODUCT $PRODUCT_ALT.yml
fi

if [ "$ARCHITECTURE" != "x64" ] && [ "$ARCHITECTURE" != "arm64" ] && [ "$ARCHITECTURE" != "ppc64le" ]
then
    echo "We only support 'x64' and 'arm64' as architecture name for -a parameter"
    exit 1
fi

if [ -z "$NOTES" ]
then
    NOTES="None"
fi

# Create temp workdirectory
DIR=`Temp_Folder_Create`
Trap_File_Delete_No_Sigchld $DIR
echo New workspace $DIR

# Copy configs
cp -v config/${PRODUCT}/* $DIR/
cp -v ../../config/${PRODUCT_ALT}*.yml $DIR/
cp -v ../../scripts/opensearch-onetime-setup.sh $DIR/
cp -v dockerfiles/opensearch-knn-3.5.0.0.zip $DIR/
cp -v dockerfiles/opensearch-ml-3.5.0.0-SNAPSHOT.zip $DIR/
cp -v dockerfiles/opensearch-neural-search-3.5.0.0-SNAPSHOT.zip $DIR/
cp -v dockerfiles/opensearch-security-3.5.0.0.zip $DIR/
cp -v dockerfiles/opensearch-job-scheduler-3.5.0.0-SNAPSHOT.zip $DIR/
cp -v dockerfiles/opensearch-alerting-3.5.0.0-SNAPSHOT.zip $DIR/
cp -r dockerfiles/opensearch-cross-cluster-replication-3.5.0.0-SNAPSHOT.zip $DIR/
cp -v dockerfiles/Dockerfile $DIR

# Copy TGZ
arch_uname=`echo ${ARCHITECTURE} | sed 's/x64/x86_64/g;s/arm64/aarch64/g'`
if [ -z "$TARBALL" ]; then
    # No tarball file specified so use local build
    LOCAL_TAR="./opensearch-min-3.5.0-linux-ppc64le.tar.gz"
    if [ -f "$LOCAL_TAR" ]; then
        echo -e "\nUsing locally built ${PRODUCT} arch ${ARCHITECTURE} version ${VERSION} from ${LOCAL_TAR}"
        cp -v $LOCAL_TAR $DIR/opensearch-core-ppc64le.tgz
        file $DIR/opensearch-core-ppc64le.tgz
        ls -l $DIR
    else
        echo "Error: Local tarball not found at ${LOCAL_TAR}"
        echo "Please ensure opensearch-min-3.5.0-linux-ppc64le.tar.gz exists in the same directory as this script"
        exit 1
    fi
else
    echo -e "\nCopying ${PRODUCT} arch ${ARCHITECTURE} version ${VERSION} from ${TARBALL}"
    cp -v $TARBALL $DIR/opensearch-core-ppc64le.tgz
    file $DIR/opensearch-core-ppc64le.tgz
    ls -l $DIR
fi

# Docker build
docker build --no-cache --build-arg VERSION=$VERSION --build-arg BUILD_DATE=`date -u +%Y-%m-%dT%H:%M:%SZ` --build-arg NOTES=$NOTES --secret id=artifactory_user_secret,env=artifactory_user --secret id=artifactory_token_secret,env=artifactory_token -f $DOCKERFILE $DIR -t opensearchproject/$PRODUCT:$VERSION
docker tag opensearchproject/$PRODUCT:$VERSION opensearchproject/$PRODUCT:latest
