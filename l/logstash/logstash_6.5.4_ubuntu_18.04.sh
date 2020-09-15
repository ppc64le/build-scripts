# ----------------------------------------------------------------------------
#
# Package       : logstash
# Version       : 6.5.4
# Source repo   : https://github.com/elastic/logstash.git
# Tested on     : ubuntu_18.04
# Script License: Apache License Version 2.0
# Maintainer    : Shivani Junawane <shivanij@us.ibm.com>
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
apt-get update -y && apt-get install -y ant make wget unzip tar gcc  openjdk-8-jdk openjdk-8-jre openjdk-8-jre-headless git ruby
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el
gem install rake
gem install bundler

# install jffi ( got some errors while following install logstash steps , hence had to install this as stated here https://github.com/linux-on-ibm-z/docs/wiki/Building-Logstash#4-jruby-runs-on-jvm-and-needs-a-native-library-libjffi-12so-java-foreign-language-interface-get-jffi-source-code-and-build )
wget https://github.com/jnr/jffi/archive/jffi-1.2.18.zip
unzip -u jffi-1.2.18.zip
cd jffi-jffi-1.2.18 && ant 
cd ..
rm -rf jffi-jffi-1.2.18 jffi-1.2.18.zip


# install logstash
git clone https://github.com/elastic/logstash.git
cd logstash && git checkout v6.5.4
rake bootstrap
rake plugin:install-default

# command to start logstash
# ./bin/logstash -e 'input { stdin { } } output { stdout {} }'
