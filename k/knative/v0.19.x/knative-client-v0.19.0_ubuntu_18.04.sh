# ----------------------------------------------------------------------------
#
# Package         : knative/client
# Version         : v0.19.0
# Source repo     : https://github.com/knative/client.git
# Tested on       : Ubuntu_18.04
# Script License  : Apache License, Version 2.0
# Maintainer      : Vijay Kumar H P <vijaykh1@in.ibm.com>
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
# Docker must be installed and running
# Running k8s cluster
# Go version 1.14.4
# Knative Serving and Eventing must be installed
# ----------------------------------------------------------------------------

set -e

apt-get install git -y

export GOPATH=${HOME}/go
export GOROOT=/usr/local/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH
export GOFLAGS="-mod=vendor"
export GO111MODULE=auto

#Install go packages
go get -u github.com/golang/dep/cmd/dep
#Offical ko repo doesnot support multiplatform build
#PR: https://github.com/google/ko/pull/38
#Once PR is merged, we can use "go get -u github.com/google/ko/cmd/ko"
mkdir -p ${GOPATH}/src/github.com/google && cd $_
git clone -b multi-platform-wip https://github.com/jonjohnsonjr/ko.git
cd ko/cmd/ko/
go install

#Create a local registry to push images to
docker run -it -d --name registry -p 5000:5000 ppc64le/registry:2
#Export KO_DOCKER_REPO pointing to your docker registry
host=$(kubectl get nodes -lkubernetes.io/hostname!=kind-control-plane -ojsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}')
export KO_DOCKER_REPO=$host:5000/knative

#Install knative-client
#Clone Knative client repo
mkdir -p ${GOPATH}/src/knative.dev && cd $_
git clone --branch v0.19.0 https://github.com/knative/client.git
cd client
#run the following command
hack/build.sh
#This results in `kn` binary in a directory where you executed the command. Please move the binary to a directory included in $PATH. 
cp ./kn $GOPATH/bin/
#To run all unit tests
hack/build.sh -t

# Build and Publish our test images to the docker daemon.
sed -i '35 s|ko resolve|ko resolve --platform=linux/ppc64le|' ./test/upload-test-images.sh
sed -i '38 s|ko resolve|ko resolve --platform=linux/ppc64le|' ./test/upload-test-images.sh
./test/upload-test-images.sh > log-e-test-images.txt 2>&1

# Get the names of test images
echo ""
echo "Extracting test image data"
cat log-e-test-images.txt | grep "Publishing"  | grep ":latest" | awk '{print $4}' > clienttemp.txt
count=$(cat clienttemp.txt | wc -l)
echo "Number of test images built = ${count}"
cat clienttemp.txt

# Loop to pull all the test images
while IFS= read -r test_image
do
    counter=$((counter+1))
    echo ""
    echo "Creating image #${counter} for kn client test image"
    echo "Test image is: $test_image"
    docker pull $test_image
    docker inspect $test_image | grep Arch
    sleep 3s
done < clienttemp.txt

#To run end to end tests 

test/local-e2e-tests.sh -test.timeout=30m --dockerrepo $KO_DOCKER_REPO --ingressendpoint $host 
