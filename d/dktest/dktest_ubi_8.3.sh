# ----------------------------------------------------------------------------
#
# Package               : dktest
# Version               : 0.3.0,0.3.6
# Source repo           : https://github.com/dhui/dktest
# Tested on             : Ubuntu 20.04
# Script License        : Apache License, Version 2 or later
# Passing Arguments     : Passing Arguments: 1.Version of package,
# Script License        : Apache License, Version 2 or later
# Maintainer            : Arumugam N S<asellappen@yahoo.com>/Priya Seth<sethp@us.ibm.com>
#
# Disclaimer            : This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

if [ -z "$1" ]; then
  export VERSION='v0.3.6'
else
  export VERSION=$1
fi

if [ -d "dktest" ] ; then
  rm -rf dktest
fi

# Dependency installation
sudo apt-get  install -y git golang | tee dktestdep$(date +'%m_%d_%Y')_install.log

# Download the repos
git clone https://github.com/dhui/dktest


# Build and Test dktest
cd dktest
git checkout $VERSION
ret=$?
if [ $ret -eq 0 ] ; then
 echo "$VERSION found to checkout "
else
 echo "$VERSION not found "
 exit
fi
#Start nginx  depandencies
sudo docker pull nginx
sudo chmod 757 /var/run/docker.sock
sudo docker run -d -e NGINX_ENTRYPOINT_QUIET_LOGS=1 nginx
ret=$?
if [ $ret -eq 0 ] ; then
 echo "docker run for nginx success "
else
 echo "docker run for nginx failed "
 exit
fi
#Build and test
go get -v -t ./...
ret=$?
if [ $ret -ne 0 ] ; then
  echo "Build failed "
else
  go test -v
  ret=$?
  if [ $ret -ne 0 ] ; then
    echo "Tests failed "
  else
    echo "Build & unit tests Success "
  fi
fi
