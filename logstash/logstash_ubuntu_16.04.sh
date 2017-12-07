# ----------------------------------------------------------------------------
#
# Package	: Logstash
# Version	: 5.6.3
# Source repo	: https://github.com/elastic/logstash.git
# Tested on	: ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer	: Yugandha Deshpande <yugandha@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

sudo apt-get update -y
sudo apt-get install -y openjdk-8-jdk openjdk-8-jre git curl make \
	rake tar wget unzip findutils  libzmq5 locales \
        procps gcc g++ automake glibc-source

### Setting JAVA_HOME and PATH variable
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el
export PATH=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el/bin::$ANT_HOME/bin:$PATH
export RUBY_PLATFORM=java
export JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF8"
git clone https://github.com/elastic/logstash.git
cd logstash
git checkout v5.6.3

./gradlew build
rake bootstrap
rake test:install-core
rake test:core
