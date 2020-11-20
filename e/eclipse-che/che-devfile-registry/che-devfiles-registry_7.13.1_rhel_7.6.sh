# ----------------------------------------------------------------------------
#
# Package         : eclipse/che-devfile-registry
# Version         : 7.13.1
# Source repo     : https://github.com/eclipse/che-devfile-registry
# Tested on       : rhel_7.6
# Script License  : Apache License, Version 2.0
# Maintainer      : Shivani Junawane <shivanij@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash
# ----------------------------------------------------------------------------
# Prerequisites:
#
# podman and podman-docker must be installed and running.
#
# Go version 1.13.1 or later must be installed.
#
# oc client version 4.18 must be installed.
# Deployment tested on Openshift 4.3 setup
#
# ----------------------------------------------------------------------------

VERSION=7.13.1

set -e
yum update -y
yum install git -y

export GOPATH=~/go
export GO111MODULE=auto

mkdir -p ${GOPATH}/src/github.com/eclipse && cd $_
git clone https://github.com/eclipse/che-devfile-registry.git
cd che-devfile-registry
git checkout $VERSION


# Building Image
# build Alpine image
./build.sh -t 7.13.1-alpine

# build UBI image
./build.sh -t 7.13.1-rhel  --rhel

# Uncomment below lines for creating imagestreams on Openshift 4.3
#oc new-project local-images || true
#oc policy add-role-to-group system:image-puller system:serviceaccounts --namespace=local-images || true
#HOST=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')
#podman tag quay.io/eclipse/che-devfile-registry:7.13.1-alpine $HOST/local-images/che-devfile-registry:7.13.1-alpine
#podman tag quay.io/eclipse/che-devfile-registry:7.13.1-rhel $HOST/local-images/che-devfile-registry:7.13.1-rhel

#podman login -u kubeadm -p $(oc whoami -t) --tls-verify=false $HOST
#podman push $HOST/local-images/che-devfile-registry:7.13.1-alpine --tls-verify=false
#podman push $HOST/local-images/che-devfile-registry:7.13.1-rhel --tls-verify=false

