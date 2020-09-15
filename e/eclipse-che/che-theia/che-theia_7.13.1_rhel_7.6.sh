# ----------------------------------------------------------------------------
#
# Package         : eclipse/che-theia
# Version         : 7.13.1
# Source repo     : https://github.com/eclipse/che-theia
# Tested on       : rhel_7.6
# Script License  : Apache License, Version 2.0
# Maintainer      : Vikas Kumar <kumar.vikas@in.ibm.com>
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
# npm and yarn must be installed
#
# oc client version 4.18 must be installed.
# Deployment tested on Openshift 4.3 setup
#
# ----------------------------------------------------------------------------

if [ -z "${1}" ]; then
  echo "missing github_token parameter ${0} <GITHUB_TOKEN>"
  exit 1
fi
GITHUB_TOKEN=$1

VERSION=7.13.1

set -e
yum update -y
yum install git -y
yum install rh-nodejs8 -y
source scl_source enable rh-nodejs8
npm install yarn -g

mkdir eclipseche && cd $_
git clone https://github.com/eclipse/che-theia.git
cd che-theia
git checkout $VERSION

# Building Images
# build Alpine and UBI images
./build.sh --build-args:GITHUB_TOKEN=$GITHUB_TOKEN --skip-tests

# Uncomment below lines for creating imagestreams on Openshift 4.3
#oc new-project local-images || true
#oc policy add-role-to-group system:image-puller system:serviceaccounts --namespace=local-images || true
#HOST=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')

#podman tag localhost/eclipse/che-theia:latest $HOST/local-images/che-theia:7.13.1
#podman tag localhost/eclipse/che-theia:latest-ubi8 $HOST/local-images/che-theia:7.13.1-ubi8

#podman tag localhost/eclipse/che-theia-endpoint-runtime-binary:latest $HOST/local-images/che-theia-endpoint-runtime-binary:7.13.1
#podman tag localhost/eclipse/che-theia-endpoint-runtime-binary:latest-ubi8 $HOST/local-images/che-theia-endpoint-runtime-binary:7.13.1-ubi8

#podman login -u kubeadmin -p $(oc whoami -t) --tls-verify=false $HOST

#podman push $HOST/local-images/che-theia:7.13.1 --tls-verify=false
#podman push $HOST/local-images/che-theia:7.13.1-ubi8 --tls-verify=false

#podman push $HOST/local-images/che-theia-endpoint-runtime-binary:7.13.1 --tls-verify=false
#podman push $HOST/local-images/che-theia-endpoint-runtime-binary:7.13.1-ubi8 --tls-verify=false
