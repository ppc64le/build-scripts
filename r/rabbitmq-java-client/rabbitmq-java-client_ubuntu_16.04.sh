# ----------------------------------------------------------------------------
#
# Package       : Rabbitmq_Java_Client
# Version       : 5.0
# Source repo   : https://github.com/rabbitmq/rabbitmq-public-umbrella.git
# Tested on     : ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer    : Yugandha Deshpande <yugandha@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

WORKDIR=`pwd`

sudo apt-get update -y

sudo apt-get install -y python python-simplejson openjdk-8-jdk openjdk-8-jre \
        openssl wget maven ssl-cert xsltproc zip \
        unzip make git curl libncurses5-dev \
        openssl libssl-dev \
        libncurses5 libncurses5-dev unixodbc \
        unixodbc-dev make openjdk-8-jdk \
        tar gcc wget git locales

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el
export PATH=$JAVA_HOME/bin:$PATH
export JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF-8"

sudo touch /etc/default/locale && \
    echo "LC_CTYPE=\"en_US.UTF-8\"" | sudo tee -a /etc/default/locale && \
    echo "LC_ALL=\"en_US.UTF-8\"" | sudo tee -a /etc/default/locale && \
    echo "LANG=\"en_US.UTF-8\"" | sudo tee -a /etc/default/locale && \
    sudo locale-gen en_US en_US.UTF-8 && \
    sudo DEBIAN_FRONTEND=noninteractive dpkg-reconfigure --force locales

export LC_CTYPE="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export LANG="en_US.UTF-8"

cd $WORKDIR
wget http://erlang.org/download/otp_src_20.0.tar.gz
tar xvzf otp_src_20.0.tar.gz
cd otp_src_20.0
rm -rf otp_src_20.0.tar.gz

export ERL_TOP=`pwd` && export PATH=$PATH:$ERL_TOP/bin
#Configure and build erlang
./configure && make && sudo make install
export LC_ALL="en_US.UTF-8"

cd $WORKDIR

#Building Elixir
git clone https://github.com/elixir-lang/elixir.git
cd elixir
git checkout v1.6.0
make clean test
sudo make install

cd $WORKDIR
export RABBIT_VSN=0.0.0
git clone --recursive https://github.com/rabbitmq/rabbitmq-public-umbrella.git
cd rabbitmq-public-umbrella
sudo make co && cd deps/rabbitmq_java_client && sudo ./mvnw verify
