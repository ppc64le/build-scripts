# ----------------------------------------------------------------------------
#
# Package         : keycloak-containers
# Branch          : master
# Tag             : 10.0.1
# Source repo     : https://github.com/keycloak/keycloak-containers.git
# Tested on       : rhel_7.6
# Script License  : Apache License, Version 2.0
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
set -e
yum update -y
yum install git -y

mkdir keycloak && cd $_
git clone -b 10.0.1 https://github.com/keycloak/keycloak-containers.git
cd keycloak-containers/server/

# Building Image
# build keycloak image with latest Version
podman build -t keycloak-ubi .

# Uncomment below lines for creating imagestreams on Openshift 4.3
#oc new-project keycloak || true
#oc policy add-role-to-group system:image-puller system:serviceaccounts --namespace=keycloak || true
#HOST=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')
#podman login --tls-verify=false -u kubeadmin -p $(oc whoami -t) --tls-verify=false $HOST
#podman tag keycloak-ubi $HOST/keycloak/keycloak-ubi
#podman push $HOST/keycloak/keycloak-ubi --tls-verify=false