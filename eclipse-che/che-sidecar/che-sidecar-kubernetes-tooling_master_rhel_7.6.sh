#----------------------------------------------------------------------------
#
# Package         : che-dockerfiles/che-sidecar-kubernetes-tooling
# Version         : master
# Source repo     : https://github.com/che-dockerfiles/che-sidecar-kubernetes-tooling
# Tested on       : rhel_7.7
# Script License  : Apache License, Version 2.0
# Maintainer      : Nailusha Potnuru <pnailush@in.ibm.com>
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
#
# ------------------------------------------------------------------------

VERSION=master

set -e
yum update -y
yum install git -y

mkdir che-dockerfiles && cd $_
git clone https://github.com/che-dockerfiles/che-sidecar-kubernetes-tooling
cd che-sidecar-kubernetes-tooling
git checkout $VERSION

# build che-sidecar-kubernetes-tooling docker image
# FROM image in dockerfile is "quay.io/buildah/stable:v1.14.8" is not supported for power architecture, Hence use Fedora:latest to test on power.
sed -i 's|quay.io/buildah/stable:v1.14.8|fedora:latest|g' Dockerfile
podman build --no-cache -t che-sidecar-kubernetes-tooling:latest .

# Uncomment below lines for creating imagestreams on Openshift 4.3
#oc new-project local-images || true
#oc policy add-role-to-group system:image-puller system:serviceaccounts --namespace=local-images || true
#HOST=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')
#podman tag che-sidecar-kubernetes-tooling:latest $HOST/local-images/che-sidecar-kubernetes-tooling

#podman login --tls-verify=false -u kubeadmin -p $(oc whoami -t) --tls-verify=false $HOST
#podman push --tls-verify=false $HOST/local-images/che-sidecar-kubernetes-tooling:latest
