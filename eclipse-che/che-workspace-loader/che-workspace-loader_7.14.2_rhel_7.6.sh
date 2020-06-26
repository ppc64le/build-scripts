# ----------------------------------------------------------------------------
#
# Package         : che-workspace-loader
# VERSION         : 7.14.2
# Source repo     : https://github.com/eclipse/che-workspace-loader
# Tested on       : rhel_7.6
# Script License  : EPL-2.0
# Maintainer      : Sailaja Chavali <sachav83@in.ibm.com>
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
# oc client version 4.3.21 must be installed.
# Deployment tested on Openshift 4.3 setup
#
# ----------------------------------------------------------------------------

VERSION=7.14.2

set -e
yum update -y
yum install git podman -y

mkdir eclipse && cd $_
git clone https://github.com/eclipse/che-workspace-loader.git && cd che-workspace-loader
git checkout $VERSION

# Building Image
# build che-workspace-loader image with latest Version
podman build -t che-workspace-loader:${VERSION} -f apache.Dockerfile .

# build che-workspace-loader builder image
podman build -t che-workspace-loader-builder:${VERSION} .

# Uncomment below lines for creating imagestreams on Openshift 4.3
#oc new-project workspace-loader || true
#oc policy add-role-to-group system:image-puller system:serviceaccounts --namespace=workspace-loader || true
#HOST=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')
#podman tag che-workspace-loader:${VERSION} $HOST/workspace-loader/che-workspace-loader:${VERSION}
#podman tag che-workspace-loader-builder:${VERSION} $HOST/workspace-loader/che-workspace-loader-builder:${VERSION}

#podman login --tls-verify=false -u kubeadmin -p $(oc whoami -t) --tls-verify=false $HOST
#podman push $HOST/workspace-loader/che-workspace-loader:${VERSION} --tls-verify=false
#podman push $HOST/workspace-loader/che-workspace-loader-builder:${VERSION} --tls-verify=false