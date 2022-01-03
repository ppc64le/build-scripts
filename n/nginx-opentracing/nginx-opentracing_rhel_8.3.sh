
# ---------------------------------------------------------------------
# 
# Package       : nginx-opentracing
# Version       : v0.9.0
# Tested on     : UBI 8.3
# Script License: Apache License, Version 2 or later
# Maintainer    : Raju Sah <Raju.Sah@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------

#!/bin/bash

set -ex

#Variables
REPO=https://github.com/opentracing-contrib/nginx-opentracing.git
PACKAGE_VERSION=0.9.0

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"
export BUILDPLATFORM=ppc64le
yum update -y

#install dependencies
yum install -y git gcc-c++ make openssl-devel pcre-devel \
    zlib-devel which tar rpm rpm-build wget cmake \
	python38-devel.ppc64le python38.ppc64le libarchive.ppc64le

wget https://github.com/opentracing-contrib/nginx-opentracing/blob/master/Dockerfile
#build the docker.
docker build -t opentracing-contrib/nginx-opentracing:latest  .

# LightStep
wget -O - https://github.com/lightstep/lightstep-tracer-cpp/releases/download/v0.8.1/linux-amd64-liblightstep_tracer_plugin.so.gz | gunzip -c > /usr/local/lib/liblightstep_tracer_plugin.so
# Zipkin
wget -O - https://github.com/rnburn/zipkin-cpp-opentracing/releases/download/v0.5.2/linux-amd64-libzipkin_opentracing_plugin.so.gz | gunzip -c > /usr/local/lib/libzipkin_opentracing_plugin.so
# Datadog
wget -O - https://github.com/DataDog/dd-opentracing-cpp/releases/download/v0.3.0/linux-amd64-libdd_opentracing_plugin.so.gz | gunzip -c > /usr/local/lib/libdd_opentracing_plugin.so

cd opt/ && git clone https://github.com/opentracing/opentracing-cpp.git
cd opentracing-cpp/
cmake .
make && make install && make test
cd ../

#jaegar
git clone https://github.com/jaegertracing/jaeger-client-cpp.git
cd jaeger-client-cpp/
mkdir .build && cd $_
cmake ..
make && make install
cd ../../

#datadog
git clone https://github.com/DataDog/dd-opentracing-cpp.git
cd dd-opentracing-cpp/
mkdir .build && cd $_
make && make install
cd ../../

# zipkin
git clone https://github.com/rnburn/zipkin-cpp-opentracing.git
cd zipkin-cpp-opentracing
mkdir .build && cd $_
make && make install
cd ../../

#clone the repo
git clone $REPO
cd nginx-opentracing/
git checkout v$PACKAGE_VERSION

cd ../
git clone https://github.com/nginx/nginx.git
cd nginx/
./auto/configure --add-dynamic-module=../nginx-opentracing/opentracing/
make && make install

