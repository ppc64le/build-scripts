# ----------------------------------------------------------------------------
#
# Package         : theia-ide/theia-apps/theia-docker
# Version         : master
# Source repo     : https://github.com/theia-ide/theia-apps/tree/master/theia-docker
# Tested on       : rhel_7.6
# Script License  : Apache License, Version 2.0
# Maintainer      : Amit Baheti <aramswar@in.ibm.com>
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
# podman must be installed 

# oc client version 4.18 must be installed.

# Deployment tested on Openshift 4.3 setup
#
# ----------------------------------------------------------------------------

set -e

VERSION=master
IMAGE_TAG=theiaide/theia-docker:latest

yum update -y
yum install git podman wget -y

git clone -b $VERSION https://github.com/theia-ide/theia-apps.git
cd theia-apps/theia-docker

# Building Image
podman build . -t $IMAGE_TAG

# Uncomment below lines for creating imagestreams on Openshift 4.3

# oc new-project local-images || true
# oc policy add-role-to-group system:image-puller system:serviceaccounts --namespace=local-images || true
# HOST=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')
# podman tag $IMAGE_TAG $HOST/local-images/theia-docker:latest

# podman login -u kubeadm -p $(oc whoami -t) --tls-verify=false $HOST
# podman push $HOST/local-images/theia-docker:latest --tls-verify=false