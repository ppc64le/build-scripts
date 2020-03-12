# ----------------------------------------------------------------------------
#
# Package       : logstash
# Version       : 7.6.0
# Source repo   : https://github.com/elastic/logstash.git
# Tested on     : rhel_7.6
# Script License: Apache License Version 2.0
# Maintainer    : Priya Seth <sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

WORKDIR=$1
cd $WORKDIR

# installing dependencies
yum update -y && yum install -y git make unzip tar ant ruby gcc-c++ java-1.8.0-openjdk-devel wget gzip procps shadow-utils zip which

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$PATH:$JAVA_HOME

# Install latest version of Ruby using rvm
#gpg --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -
curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import -
curl -sSL https://get.rvm.io | bash -s stable --ruby
source /usr/local/rvm/scripts/rvm
gem install rake
gem install bundler
 
# Install ant
cd $WORKDIR
wget http://apachemirror.wuchna.com//ant/binaries/apache-ant-1.10.6-bin.tar.gz
tar -zxvf apache-ant-1.10.6-bin.tar.gz
cd apache-ant-1.10.6
export ANT_HOME=/root/apache-ant-1.10.6
export PATH=${ANT_HOME}/bin:$PATH

# install jffi ( got some errors while following install logstash steps , hence had to install this as stated here 
# https://github.com/linux-on-ibm-z/docs/wiki/Building-Logstash#4-jruby-runs-on-jvm-and-needs-a-native-library-libjffi-
#12so-java-foreign-language-interface-get-jffi-source-code-and-build )
cd $WORKDIR
wget https://github.com/jnr/jffi/archive/jffi-1.2.18.zip
unzip -u jffi-1.2.18.zip
cd jffi-jffi-1.2.18 && ant
cd ..
rm -rf jffi-jffi-1.2.18 jffi-1.2.18.zip

#install jruby-9.1.12.0
rvm install "jruby-9.1.12.0"

# install logstash
cd $WORKDIR
git clone https://github.com/elastic/logstash.git
cd logstash && git checkout v7.6.0
sed -i '2d' ./rakelib/artifacts.rake
rake bootstrap
rake plugin:install-default

# patch from https://github.com/mew2057/CAST/blob/6c7f7d514b7af3c512635ec145aa829c535467dc/csm_big_data/config-scripts/logstashFixupScript.sh 
STARTDIR=$(pwd)
JARDIR="${STARTDIR}/logstash-core/lib/jars"
JAR="jruby-complete-9.2.9.0.jar"
JRUBYDIR="${JAR}-dir"
PLATDIR="META-INF/jruby.home/lib/ruby/stdlib/ffi/platform/powerpc64le-linux"

cd ${JARDIR}
unzip -d ${JRUBYDIR} ${JAR}
cd "${JRUBYDIR}/${PLATDIR}"
cp -n types.conf platform.conf
cd "${JARDIR}/${JRUBYDIR}"

zip -r jruby-complete-9.2.9.0.jar *
mv  -f jruby-complete-9.2.9.0.jar ..
cd ${JARDIR}
rm -rf ${JRUBYDIR}

sync
sync
cd ${STARTDIR}


# command to start logstash
# ./bin/logstash -e 'input { stdin { } } output { stdout {} }'
