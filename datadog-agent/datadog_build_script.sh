 # ----------------------------------------------------------------------------
 #
 # Package        : Datadog-Agent
 # Version        : 7.21.0
 # Source repo    : https://github.com/DataDog/datadog-agent.git
 # Tested on      : RHEL 8.2
 # Script License : Apache License, Version 2 or later
 # Maintainer     : Sachin Itagi <Sachin.Itagi@ibm.com>
 #
 # Disclaimer: This script has been tested in root mode on given
 # ==========  platform using the mentioned version of the package.
 #             It may not work as expected with newer versions of the
 #             package and/or distribution. In such case, please
 #             contact "Maintainer" of this script.
 #
 # ----------------------------------------------------------------------------
 
 #!/bin/bash

 WORKDIR=`pwd`

 # Install all dependencies
 yum install -y wget git python36 python36-devel python38 python38-devel openssl openssl-devel make gcc gcc-c++ diffutils
 
 wget https://dl.google.com/go/go1.13.5.linux-ppc64le.tar.gz 
 tar -C /usr/local -xzf go1.13.5.linux-ppc64le.tar.gz 
 rm -rf go1.13.5.linux-ppc64le.tar.gz
 export PATH=$PATH:/usr/local/go/bin 
 export GOPATH=/root/go 
 go version
 python3 -m pip install --upgrade pip 
 
 # Compile and Install cmake 
 wget http://www.cmake.org/files/v3.16/cmake-3.16.4.tar.gz 
 tar xzf cmake-3.16.4.tar.gz
 rm -rf  cmake-3.16.4.tar.gz
 cd cmake-3.16.4 
 ./bootstrap 
 make 
 make install 
 cmake --version

 # Clone datadog-agent, build and execute unit tests
 git clone https://github.com/DataDog/datadog-agent.git $GOPATH/src/github.com/DataDog/datadog-agent
 cd $GOPATH/src/github.com/DataDog/datadog-agent
 export PATH=$PATH:/$GOPATH/bin
 pip install -r requirements.txt 
 invoke deps 
 invoke agent.build --build-exclude=systemd
 go get -u github.com/golangci/golangci-lint/cmd/golangci-lint
 invoke  -e test --build-exclude=systemd --python-runtimes 3 --coverage --race --profile --fail-on-fmt --cpus 3
