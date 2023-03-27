#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package       : apache-avro
# Version       : release-1.11.1
# Source repo   : https://github.com/apache/avro
# Tested on     : UBI 8.5
# Language      : Java
# Travis-Check  : False
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
PACKAGE_VERSION=${1:-release-1.11.1}
PACKAGE_URL=https://github.com/apache/avro

dnf module list ruby
dnf module reset ruby -y
dnf module enable ruby:2.6 -y
dnf module -y update ruby:2.6
yum install -y ruby
ruby -v
yum install -y rubygem-rake ruby-devel
yum install -y wget git curl make  gcc-c++ cmake  fontconfig fontconfig-devel glib2 glib2-devel jansson perl  python3 python3-pip
yum install -y urw-base35-fonts.noarch urw-base35-fonts-common.noarch
yum install -y adobe-mappings-cmap.noarch adobe-mappings-cmap-deprecated.noarch adobe-mappings-pdf.noarch google-droid-sans-fonts.noarch

#installing java-11
yum install -y java-11-openjdk-devel
export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-11)(?=.*ppc64le)')
export PATH=$JAVA_HOME/bin:$PATH

# maven 3.8.6 installation
wget http://archive.apache.org/dist/maven/maven-3/3.8.6/binaries/apache-maven-3.8.6-bin.tar.gz
tar -xvzf apache-maven-3.8.6-bin.tar.gz
cp -R apache-maven-3.8.6 /usr/local
ln -s /usr/local/apache-maven-3.8.6/bin/mvn /usr/bin/mvn
export M2_HOME=/usr/local/maven
export PATH=$PATH:$M2_HOME/bin

#steps to install ant
wget -c https://mirrors.advancedhosters.com/apache/ant/binaries/apache-ant-1.10.12-bin.zip
unzip apache-ant-1.10.12-bin.zip
mv apache-ant-1.10.12/ /usr/local/ant
ANT_HOME="/usr/local/ant"
PATH="$PATH:/usr/local/ant/bin"
export ANT_HOME="/usr/local/ant"
export PATH="$PATH:/usr/local/ant/bin"
ant -version
echo "------------------------------------------------------ANT INSTALLED------------------------------------------"

#steps to install m4 which is required by bison
wget  https://rpmfind.net/linux/centos/8-stream/BaseOS/ppc64le/os/Packages/m4-1.4.18-7.el8.ppc64le.rpm
rpm -i m4-1.4.18-7.el8.ppc64le.rpm
m4 --version
echo "------------------------------------------------------M4 INSTALLED------------------------------------------"

#steps to install bison
wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/bison-3.0.4-10.el8.ppc64le.rpm
rpm -i bison-3.0.4-10.el8.ppc64le.rpm
bison --version
echo "------------------------------------------------------BISON INSTALLED------------------------------------------"

#steps to install ctags
wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/ctags-5.8-23.el8.ppc64le.rpm
rpm -i ctags-5.8-23.el8.ppc64le.rpm
ctags --version
echo "------------------------------------------------------CTAGS INSTALLED------------------------------------------"

#stepd to install flex
wget  https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/flex-2.6.1-9.el8.ppc64le.rpm
rpm -i flex-2.6.1-9.el8.ppc64le.rpm
flex --version
echo "------------------------------------------------------FLEX INSTALLED------------------------------------------"

#steps to install doxygen
wget https://rpmfind.net/linux/centos/8-stream/PowerTools/ppc64le/os/Packages/doxygen-1.8.14-12.el8.ppc64le.rpm
rpm -i doxygen-1.8.14-12.el8.ppc64le.rpm
doxygen --version
echo "------------------------------------------------------DOXYGEN INSTALLED------------------------------------------"

#setps to install jansson-devel
wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/jansson-devel-2.14-1.el8.ppc64le.rpm
rpm -i jansson-devel-2.14-1.el8.ppc64le.rpm
echo "------------------------------------------------------JANSSON-DEVEL INSTALLED------------------------------------------"

#steps to install snappy
wget https://rpmfind.net/linux/centos/8-stream/BaseOS/ppc64le/os/Packages/snappy-1.1.8-3.el8.ppc64le.rpm
rpm -i snappy-1.1.8-3.el8.ppc64le.rpm
echo "------------------------------------------------------SNAPPY INSTALLED------------------------------------------"

#steps to install snappy-devel
wget https://rpmfind.net/linux/centos/8-stream/PowerTools/ppc64le/os/Packages/snappy-devel-1.1.8-3.el8.ppc64le.rpm
rpm -i snappy-devel-1.1.8-3.el8.ppc64le.rpm
echo "------------------------------------------------------SNAPPY-DEVEL INSTALLED------------------------------------------"

wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/boost-system-1.66.0-13.el8.ppc64le.rpm
rpm -i boost-system-1.66.0-13.el8.ppc64le.rpm
echo "------------------------------------------------------boost-system INSTALLED------------------------------------------"

wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/boost-thread-1.66.0-13.el8.ppc64le.rpm
rpm -i boost-thread-1.66.0-13.el8.ppc64le.rpm
echo "------------------------------------------------------boost-thread INSTALLED------------------------------------------"

wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/boost-context-1.66.0-13.el8.ppc64le.rpm
rpm -i boost-context-1.66.0-13.el8.ppc64le.rpm
echo "------------------------------------------------------boost-context INSTALLED------------------------------------------"

wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/boost-chrono-1.66.0-13.el8.ppc64le.rpm
rpm -i boost-chrono-1.66.0-13.el8.ppc64le.rpm
echo "------------------------------------------------------boost-chrono INSTALLED------------------------------------------"

wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/boost-coroutine-1.66.0-13.el8.ppc64le.rpm
rpm -i boost-coroutine-1.66.0-13.el8.ppc64le.rpm
echo "------------------------------------------------------boost-coroutine INSTALLED------------------------------------------"

wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/boost-type_erasure-1.66.0-13.el8.ppc64le.rpm
rpm -i boost-type_erasure-1.66.0-13.el8.ppc64le.rpm
echo "------------------------------------------------------boost-type_erasure INSTALLED------------------------------------------"

wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/boost-timer-1.66.0-13.el8.ppc64le.rpm
rpm -i boost-timer-1.66.0-13.el8.ppc64le.rpm
echo "------------------------------------------------------boost-timer INSTALLED------------------------------------------"

wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/boost-test-1.66.0-13.el8.ppc64le.rpm
rpm -i boost-test-1.66.0-13.el8.ppc64le.rpm
echo "------------------------------------------------------boost-test INSTALLED------------------------------------------"

wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/boost-stacktrace-1.66.0-13.el8.ppc64le.rpm
rpm -i boost-stacktrace-1.66.0-13.el8.ppc64le.rpm
echo "------------------------------------------------------boost-stacktrace INSTALLED------------------------------------------"

wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/boost-signals-1.66.0-13.el8.ppc64le.rpm
rpm -i boost-signals-1.66.0-13.el8.ppc64le.rpm
echo "------------------------------------------------------boost-signals INSTALLED------------------------------------------"

wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/boost-serialization-1.66.0-13.el8.ppc64le.rpm
rpm -i boost-serialization-1.66.0-13.el8.ppc64le.rpm
echo "------------------------------------------------------boost-serialization INSTALLED------------------------------------------"

wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/boost-random-1.66.0-13.el8.ppc64le.rpm
rpm -i boost-random-1.66.0-13.el8.ppc64le.rpm
echo "------------------------------------------------------boost-random INSTALLED------------------------------------------"

wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/boost-program-options-1.66.0-13.el8.ppc64le.rpm
rpm -i boost-program-options-1.66.0-13.el8.ppc64le.rpm
echo "------------------------------------------------------boost-program-options INSTALLED------------------------------------------"

wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/boost-math-1.66.0-13.el8.ppc64le.rpm
rpm -i boost-math-1.66.0-13.el8.ppc64le.rpm
echo "------------------------------------------------------boost-math INSTALLED------------------------------------------"

wget https://rpmfind.net/linux/centos/8-stream/BaseOS/ppc64le/os/Packages/libicu-60.3-2.el8_1.ppc64le.rpm
rpm -i libicu-60.3-2.el8_1.ppc64le.rpm
echo "------------------------------------------------------libicu INSTALLED------------------------------------------"

wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/boost-filesystem-1.66.0-13.el8.ppc64le.rpm
rpm -i boost-filesystem-1.66.0-13.el8.ppc64le.rpm
echo "------------------------------------------------------boost-filesystem- INSTALLED------------------------------------------"

wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/boost-date-time-1.66.0-13.el8.ppc64le.rpm
rpm -i boost-date-time-1.66.0-13.el8.ppc64le.rpm
echo "------------------------------------------------------boost-date-time INSTALLED------------------------------------------"

wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/boost-atomic-1.66.0-13.el8.ppc64le.rpm
rpm -i boost-atomic-1.66.0-13.el8.ppc64le.rpm
echo "------------------------------------------------------boost-atomic INSTALLED------------------------------------------"

wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/boost-regex-1.66.0-13.el8.ppc64le.rpm
rpm -i boost-regex-1.66.0-13.el8.ppc64le.rpm
echo "------------------------------------------------------boost-regex INSTALLED------------------------------------------"

wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/boost-log-1.66.0-13.el8.ppc64le.rpm
rpm -i boost-log-1.66.0-13.el8.ppc64le.rpm
echo "------------------------------------------------------boost-log INSTALLED------------------------------------------"

wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/boost-locale-1.66.0-13.el8.ppc64le.rpm
rpm -i boost-locale-1.66.0-13.el8.ppc64le.rpm
echo "------------------------------------------------------boost-locale INSTALLED------------------------------------------"

wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/boost-iostreams-1.66.0-13.el8.ppc64le.rpm
rpm -i boost-iostreams-1.66.0-13.el8.ppc64le.rpm
echo "------------------------------------------------------boost-iostreams INSTALLED------------------------------------------"

wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/boost-graph-1.66.0-13.el8.ppc64le.rpm
rpm -i boost-graph-1.66.0-13.el8.ppc64le.rpm
echo "------------------------------------------------------boost-graph INSTALLED------------------------------------------"

wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/boost-fiber-1.66.0-13.el8.ppc64le.rpm
rpm -i boost-fiber-1.66.0-13.el8.ppc64le.rpm
echo "------------------------------------------------------boost-fiber INSTALLED------------------------------------------"

wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/boost-container-1.66.0-13.el8.ppc64le.rpm
rpm -i boost-container-1.66.0-13.el8.ppc64le.rpm
echo "------------------------------------------------------boost-container INSTALLED------------------------------------------"

#steps to install interdependencies
wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/boost-wave-1.66.0-13.el8.ppc64le.rpm
rpm -i boost-wave-1.66.0-13.el8.ppc64le.rpm
echo "------------------------------------------------------boost-wave INSTALLED------------------------------------------"

wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/boost-1.66.0-13.el8.ppc64le.rpm
rpm -i boost-1.66.0-13.el8.ppc64le.rpm
echo "------------------------------------------------------boost INSTALLED------------------------------------------"

wget https://rpmfind.net/linux/centos/8-stream/BaseOS/ppc64le/os/Packages/libicu-devel-60.3-2.el8_1.ppc64le.rpm
rpm -i libicu-devel-60.3-2.el8_1.ppc64le.rpm
echo "------------------------------------------------------libicu-devel INSTALLED------------------------------------------"

wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/boost-devel-1.66.0-13.el8.ppc64le.rpm
rpm -i boost-devel-1.66.0-13.el8.ppc64le.rpm
echo "------------------------------------------------------boost-devel INSTALLED------------------------------------------"

#steps to install boost
wget http://sourceforge.net/projects/boost/files/boost/1.47.0/boost_1_47_0.tar.gz
tar -xvzf boost_1_47_0.tar.gz
mv boost_1_47_0 /usr/local/
export BOOST_ROOT=usr/local/boost_1_47_0
export PATH=$PATH:$BOOST_ROOT
echo "------------------------------------------------------BOOST INSTALLED------------------------------------------"

#source-heighlight
wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/source-highlight-3.1.8-17.el8.ppc64le.rpm
rpm -i source-highlight-3.1.8-17.el8.ppc64le.rpm
echo "------------------------------------------------------SOURCE-HEIGHLIGHT INSTALLED------------------------------------------"

#inter for subversion-lib-5mod
wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/utf8proc-2.1.1-5.module_el8.4.0+632+d2bf8782.ppc64le.rpm
rpm -i utf8proc-2.1.1-5.module_el8.4.0+632+d2bf8782.ppc64le.rpm
echo "------------------------------------------------------UTF8PROC INSTALLED------------------------------------------"

#inter for subversion-lib-5mod
wget https://www.rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/apr-1.6.3-12.el8.ppc64le.rpm
rpm -i apr-1.6.3-12.el8.ppc64le.rpm
echo "------------------------------------------------------APR INSTALLED------------------------------------------"

#inter for subversion-lib-5mod
wget https://www.rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/apr-util-1.6.1-6.el8.ppc64le.rpm
rpm -i apr-util-1.6.1-6.el8.ppc64le.rpm
echo "------------------------------------------------------APR-UTIL INSTALLED------------------------------------------"

#inter for subversion-lib-5mod
wget https://www.rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/libserf-1.3.9-9.module_el8.4.0+632+d2bf8782.ppc64le.rpm
rpm -i libserf-1.3.9-9.module_el8.4.0+632+d2bf8782.ppc64le.rpm
echo "------------------------------------------------------LIBSERF INSTALLED------------------------------------------"

#inter for subversion-5mod
wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/subversion-libs-1.10.2-5.module_el8.7.0+1146+633d65ff.ppc64le.rpm
rpm -i  subversion-libs-1.10.2-5.module_el8.7.0+1146+633d65ff.ppc64le.rpm
echo "------------------------------------------------------SUBVERSION-LIBS INSTALLED------------------------------------------"

#subversion installation
wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/subversion-1.10.2-5.module_el8.7.0+1146+633d65ff.ppc64le.rpm
rpm -i  subversion-1.10.2-5.module_el8.7.0+1146+633d65ff.ppc64le.rpm
echo "------------------------------------------------------SUBVERSION INSTALLED------------------------------------------"

#inter for ascii doc
wget https://rpmfind.net/linux/centos/8-stream/BaseOS/ppc64le/os/Packages/sgml-common-0.6.3-50.el8.noarch.rpm
rpm -i sgml-common-0.6.3-50.el8.noarch.rpm
echo "------------------------------------------------------SGML-COMMON INSTALLED------------------------------------------"

#inter for docbook-dtds
wget https://rpmfind.net/linux/centos/8-stream/BaseOS/ppc64le/os/Packages/xml-common-0.6.3-50.el8.noarch.rpm
rpm -i xml-common-0.6.3-50.el8.noarch.rpm
echo "------------------------------------------------------XML-COMMON INSTALLED------------------------------------------"

#inter for ascii doc
wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/docbook-dtds-1.0-69.el8.noarch.rpm
rpm -i docbook-dtds-1.0-69.el8.noarch.rpm
echo "------------------------------------------------------DOCBOOK-DTDS INSTALLED------------------------------------------"

#inter for ascii doc
wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/docbook-style-xsl-1.79.2-9.el8.noarch.rpm
rpm -i docbook-style-xsl-1.79.2-9.el8.noarch.rpm
echo "------------------------------------------------------DOCKBOOK-STYLE-XSL INSTALLED------------------------------------------"

#inter for graphviz
wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/xorg-x11-fonts-ISO8859-1-100dpi-7.5-19.el8.noarch.rpm
rpm -i xorg-x11-fonts-ISO8859-1-100dpi-7.5-19.el8.noarch.rpm
echo "------------------------------------------------------XORG-X11-FONTS INSTALLED------------------------------------------"

#inter for graphviz
wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/libXpm-3.5.12-9.el8.ppc64le.rpm
rpm -i libXpm-3.5.12-9.el8.ppc64le.rpm
echo "------------------------------------------------------LIBXPM INSTALLED------------------------------------------"

#inter for graphviz
wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/libXaw-1.0.13-10.el8.ppc64le.rpm
rpm -i libXaw-1.0.13-10.el8.ppc64le.rpm
echo "------------------------------------------------------LIBXAW INSTALLED------------------------------------------"

#inter for graphviz
wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/libwebp-1.0.0-5.el8.ppc64le.rpm
rpm -i libwebp-1.0.0-5.el8.ppc64le.rpm
echo "------------------------------------------------------LIBWEBP INSTALLED------------------------------------------"

#inter for graphviz
wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/gd-2.2.5-7.el8.ppc64le.rpm
rpm -i gd-2.2.5-7.el8.ppc64le.rpm
echo "------------------------------------------------------GD INSTALLED------------------------------------------"

#inter for graphviz
wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/libidn-1.34-5.el8.ppc64le.rpm
rpm -i libidn-1.34-5.el8.ppc64le.rpm
echo "------------------------------------------------------LIBIDN INSTALLED------------------------------------------"

#inter for graphviz
wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/openjpeg2-2.4.0-5.el8.ppc64le.rpm
rpm -i openjpeg2-2.4.0-5.el8.ppc64le.rpm
echo "------------------------------------------------------OPENINGJPEG2 INSTALLED------------------------------------------"

#inter for graphviz
wget https://rpmfind.net/linux/centos/8-stream/BaseOS/ppc64le/os/Packages/libtool-ltdl-2.4.6-25.el8.ppc64le.rpm
rpm -i libtool-ltdl-2.4.6-25.el8.ppc64le.rpm
echo "------------------------------------------------------LIBTOOL-LTDL INSTALLED------------------------------------------"

#inter for graphviz
wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/libpng15-1.5.30-7.el8.ppc64le.rpm
rpm -i libpng15-1.5.30-7.el8.ppc64le.rpm
echo "------------------------------------------------------LIBPNG15 INSTALLED------------------------------------------"

#inter for graphviz
wget http://bay.uchicago.edu/centos-altarch/7/os/ppc64le/Packages/libpaper-1.1.24-9.el7.ppc64le.rpm
rpm -i libpaper-1.1.24-9.el7.ppc64le.rpm
echo "------------------------------------------------------LIBPAPER INSTALLED------------------------------------------"

#inter for graphviz
wget http://bay.uchicago.edu/centos-altarch/7/os/ppc64le/Packages/libgs-9.25-5.el7.ppc64le.rpm
rpm -i libgs-9.25-5.el7.ppc64le.rpm
echo "------------------------------------------------------LIBGS INSTALLED------------------------------------------"

#inter for graphviz
wget http://bay.uchicago.edu/centos-altarch/7/os/ppc64le/Packages/librsvg2-2.40.20-1.el7.ppc64le.rpm
rpm -i librsvg2-2.40.20-1.el7.ppc64le.rpm
echo "-----------------------------------------------------LIBRSVG2- INSTALLED------------------------------------------"

#inter for asciidoc
wget https://rpmfind.net/linux/centos/8-stream/BaseOS/ppc64le/os/Packages/libxslt-1.1.32-6.el8.ppc64le.rpm
rpm -i libxslt-1.1.32-6.el8.ppc64le.rpm
echo "------------------------------------------------------LIBXSLT INSTALLED------------------------------------------"


#wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/gtk2-2.24.32-5.el8.ppc64le.rpm
#rpm -i gtk2-2.24.32-5.el8.ppc64le.rpm
#echo "------------------------------------------------------GTK2 INSTALLED------------------------------------------"


#inter for asciidoc
wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/graphviz-2.40.1-43.el8.ppc64le.rpm
rpm -i graphviz-2.40.1-43.el8.ppc64le.rpm
echo "------------------------------------------------------GRAPHVIZ INSTALLED------------------------------------------"

#asciidoc installation
wget https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/asciidoc-8.6.10-0.5.20180627gitf7c2274.el8.noarch.rpm
rpm -i asciidoc-8.6.10-0.5.20180627gitf7c2274.el8.noarch.rpm
echo "------------------------------------------------------ASCIIDOC INSTALLED------------------------------------------"

# Install Forrest
mkdir -p /usr/local/apache-forrest
curl -O http://archive.apache.org/dist/forrest/0.8/apache-forrest-0.8.tar.gz
tar xzf *forrest* --strip-components 1 -C /usr/local/apache-forrest
echo 'forrest.home=/usr/local/apache-forrest' > build.properties
chmod -R 0777 /usr/local/apache-forrest/build /usr/local/apache-forrest/main /usr/local/apache-forrest/plugins
export FORREST_HOME=/usr/local/apache-forrest
echo "------------------------------------------------------FORREST INSTALLED------------------------------------------"

# Install Perl modules
curl -L https://cpanmin.us | perl - App::cpanminus
cpanm install Module::Install Module::Install::ReadmeFromPod \
  Module::Install::Repository \
  Math::BigInt JSON::XS Try::Tiny Regexp::Common Encode \
  IO::String Object::Tiny Compress::Zlib Test::More \
  Test::Exception Test::Pod
echo "------------------------------------------------------PERL MODULES INSTALLED------------------------------------------"

# Install Ruby modules
gem install multi_json bundle
echo "------------------------------------------------------RUBY MODULES INSTALLED------------------------------------------"

# Install global Node modules
curl -sL https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh -o install_nvm.sh
sh install_nvm.sh
source /root/.nvm/nvm.sh
nvm install 8.14.0
npm install -g grunt-cli
echo "------------------------------------------------------NODE MODULES INSTALLED------------------------------------------"

# Install AVRO
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION
echo "------------------------------------------------------AVRO INSTALLED------------------------------------------"

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
fi

