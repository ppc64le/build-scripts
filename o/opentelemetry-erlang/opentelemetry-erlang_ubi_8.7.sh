#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : opentelemetry-erlang
# Version          : main
# Source repo      : https://github.com/open-telemetry/opentelemetry-erlang
# Tested on        : ubi:8.7
# Language         : Erlang
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Pratik Tonage <Pratik.Tonage@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#   
# ----------------------------------------------------------------------------

PACKAGE_NAME=opentelemetry-erlang
PACKAGE_VERSION=${1:-"main"}
PACKAGE_URL=https://github.com/open-telemetry/opentelemetry-erlang
HOME_DIR=$PWD

#Install docker 
sudo dnf install -y yum-utils device-mapper-persistent-data lvm2
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo docker-compose-plugin
sudo dnf install -y docker-ce docker-ce-cli containerd.io
sudo systemctl enable docker
#Commenting out below command, as docker inside docker is disabled in currency.
#systemctl start docker

sudo yum install -y yum-utils autoconf gawk gcc gcc-c++ gzip libxml2-devel libxslt ncurses-devel openssl-devel make tar unixODBC-devel wget git

#Install erlang/otp-25.0.3
cd $HOME_DIR
git clone https://github.com/erlang/otp.git
cd otp
git checkout OTP-25.0.3
./configure
make -j2
sudo make install
cd ..

#Install rebar3
cd $HOME_DIR
git clone https://github.com/erlang/rebar3.git
cd rebar3/
git checkout 3.19.0
./bootstrap
./rebar3 local install
export PATH=~/.cache/rebar3/bin:$PATH
cd ..

#Clone the repository and build.
cd $HOME_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Commenting out below command, as docker inside docker is disabled in currency.
#sudo docker compose up -d

#Compile
if ! rebar3 compile; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

#Eunit tests
rebar3 eunit --cover
if ! rebar3 eunit --cover; then
    echo "------------------$PACKAGE_NAME:install_success_but_Eunit_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME" 
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $OS_NAME | GitHub | Fail |  Install_success_but_Eunit_test_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:Install_&_Eunit_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $OS_NAME | GitHub  | Pass |  Both_Install_and_Eunit_Test_Success"
    exit 0
fi

#Commenting below,the code requires a docker container, docker-compose for tests and we can't install docker in a container in currency.
#Common tests
#rebar3 ct --cover
#Here we are building default branch i.e main,because on latest tag/release (v1.3.0) we are facing 1 test failure,
#For that failure they did some updates in main branch (commit id:ca03dd1) and after that all test cases are passing on main branch.
#Once they release the next release/tag, we'll build it and add it to the script.
