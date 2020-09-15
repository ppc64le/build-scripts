#----------------------------------------------------------------------------------------
#
# Package			: openshift/knative-client
# Version			: v0.13.2
# Source repo		: https://github.com/openshift/knative-client
# Tested on			: RHEL 7.6
# Script License	: Apache License Version 2.0
# Maintainer		: Pratham Murkute <prathamm@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
# 			  Prerequisites: "Go" version 1.13.5 or higher must be installed
#
#----------------------------------------------------------------------------------------

#!/bin/bash

# environment variables & setup
mkdir -p $HOME/go
mkdir -p $HOME/go/src
mkdir -p $HOME/go/bin
mkdir -p $HOME/go/pkg
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

# build "kn" CLI binary
mkdir -p $GOPATH/src/github.com/openshift && cd $_ && pwd
git clone https://github.com/openshift/knative-client.git
cd knative-client && pwd
#git checkout release-v0.13.2
git checkout -b v0.13.2 tags/openshift-v0.13.2
git branch -vv

# compile the code
# executes ./hack/build.sh -f
echo "Building the code.."
export GOFLAGS="-v -x" #print the commands & print the names of packages as they are compiled
make build > kn-cli-build.txt 2>&1
./kn version | tee kn-cli-version.txt 2>&1

# run the unit tests
# executes the ./hack/build.sh -t
echo "Executing the unit tests.."
export GOFLAGS="" #only print unit test results
#sed -i '149 s|go test -v|go test -v -count=1|' ./hack/build.sh #to disable test caching explicitly use -count=1
sed -i '157 s|rm|cp $test_output ./kn-cli-unittest.txt \&\& rm|' ./hack/build.sh #copy test log before deleting
make test-unit
echo "Build and unit test complete.."
