#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package       : apache-avro
# Version       : release-1.11.3
# Source repo   : https://github.com/apache/avro
# Tested on     : UBI: 9.3
# Language      : Java
# Ci-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer    : Stuti Wali <Stuti.Wali@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

PACKAGE_NAME=avro
PACKAGE_VERSION=${1:-release-1.11.3}
PACKAGE_URL=https://github.com/apache/avro
NODE_VERSION=${NODE_VERSION:-18.20.2}
HOME_DIR=`pwd`
export NODE_OPTIONS="--dns-result-order=ipv4first"

yum install -y wget
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/
wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official


dnf module list ruby
dnf module reset ruby -y
dnf module enable ruby:3.1 -y
dnf module -y update ruby:3.1
yum install -y ruby
ruby -v
yum install -y rubygem-rake ruby-devel
yum install -y wget git make  gcc-c++ cmake  fontconfig fontconfig-devel glib2 glib2-devel jansson perl  python3 python3-pip gtk2 gtk3 gtk-update-icon-cache
yum install -y urw-base35-fonts.noarch urw-base35-fonts-common.noarch

#installing java-11
yum install -y java-11-openjdk-devel
export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-11)(?=.*ppc64le)')
export PATH=$JAVA_HOME/bin:$PATH
java -version

# maven installation
wget https://archive.apache.org/dist/maven/maven-3/3.9.1/binaries/apache-maven-3.9.1-bin.tar.gz
tar -xvzf apache-maven-3.9.1-bin.tar.gz
cp -R apache-maven-3.9.1 /usr/local
ln -s /usr/local/apache-maven-3.9.1/bin/mvn /usr/bin/mvn
export M2_HOME=/usr/local/maven
export PATH=$PATH:$M2_HOME/bin
mvn -version


#steps to install ant
wget -c https://mirrors.advancedhosters.com/apache/ant/binaries/apache-ant-1.10.13-bin.zip
unzip apache-ant-1.10.13-bin.zip
mv apache-ant-1.10.13/ /usr/local/ant
ANT_HOME="/usr/local/ant"
PATH="$PATH:/usr/local/ant/bin"
export ANT_HOME="/usr/local/ant"
export PATH="$PATH:/usr/local/ant/bin"
ant -version

yum install -y bison bison-devel flex doxygen jansson-devel snappy snappy-devel libicu libicu-devel boost-system boost-thread boost-context boost-chrono boost-coroutine boost-type_erasure boost-timer boost-test boost-stacktrace  boost-serialization boost-random boost-program-options boost-math boost-filesystem boost-date-time boost-atomic boost-regex boost-log boost-locale boost-iostreams boost-graph boost-fiber boost-container boost-wave boost boost-devel 

yum install -y source-highlight utf8proc apr apr-util-devel libserf subversion-libs subversion sgml-common.noarch xml-common.noarch docbook-dtds.noarch docbook-style-xsl.noarch xorg-x11-fonts-ISO8859-1-100dpi.noarch libXpm libXaw libwebp gd libidn2 openjpeg2 libtool-ltdl libpng15 libpaper libgs librsvg2 libxslt graphviz asciidoc.noarch 
 

# Install Forrest
mkdir -p /usr/local/apache-forrest
wget https://archive.apache.org/dist/forrest/0.8/apache-forrest-0.8.tar.gz
tar xzf *forrest* --strip-components 1 -C /usr/local/apache-forrest
echo 'forrest.home=/usr/local/apache-forrest' > build.properties
chmod -R 0777 /usr/local/apache-forrest/build /usr/local/apache-forrest/main /usr/local/apache-forrest/plugins
export FORREST_HOME=/usr/local/apache-forrest

# Install Perl modules
yum install -y cpanminus
cpanm install Module::Install Module::Install::ReadmeFromPod \
  Module::Install::Repository \
  Math::BigInt JSON::XS Try::Tiny Regexp::Common Encode \
  IO::String Object::Tiny Compress::Zlib Test::More \
  Test::Exception Test::Pod


# Install Ruby modules
gem install multi_json bundle

# Install global Node modules
wget https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-ppc64le.tar.gz
tar -xzf node-v${NODE_VERSION}-linux-ppc64le.tar.gz
export PATH=$HOME_DIR/node-v${NODE_VERSION}-linux-ppc64le/bin:$PATH
node -v
npm -v
npm install -g grunt-cli

# Install AVRO
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

#build and test package
if ! mvn clean install -PallModules -Drat.numUnapprovedLicenses=200 -DskipTests; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 1
fi
if ! mvn test -PallModules -Drat.numUnapprovedLicenses=200; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 0
fi







