# ----------------------------------------------------------------------------
#
# Package         : che-cert-manager-ca-cert-generator-image
# Version         : master
# Source repo     : https://github.com/che-dockerfiles/che-cert-manager-ca-cert-generator-image
# Tested on       : rhel_7.6
# Script License  : Apache License, Version 2.0
# Maintainer      : Bivas Das <bivasda1@ibm.com>
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
# docker version supporting multistage builds must be installed and running.
#
# The internal resgistry should be set as insecure registry in docker daemon settings.
#
# oc client version 4.18 or above must be installed.
# Deployment tested on Openshift 4.3 setup
#
# ----------------------------------------------------------------------------

VERSION=master

set -e
yum update -y
yum install git -y

mkdir -p che-dockerfiles && cd $_
git clone https://github.com/che-dockerfiles/che-cert-manager-ca-cert-generator-image.git
cd che-cert-manager-ca-cert-generator-image
git checkout $VERSION

# build UBI image
TAG=$(git rev-parse --short HEAD)
./build.sh

# Uncomment below lines for creating imagestreams on Openshift 4.3
#oc new-project che-cert-manager-ca-cert-generator-image || true
#oc policy add-role-to-group system:image-puller system:serviceaccounts --namespace=che-cert-manager-ca-cert-generator-image || true
#HOST=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')
#docker tag quay.io/eclipse/che-cert-manager-ca-cert-generator:$TAG  $HOST/che-cert-manager-ca-cert-generator-image/che-cert-manager-ca-cert-generator-image:latest
#docker login -u kubeadm -p $(oc whoami -t) $HOST
#docker push $HOST/che-cert-manager-ca-cert-generator-image/che-cert-manager-ca-cert-generator-image:latest
