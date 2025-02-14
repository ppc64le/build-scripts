#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : prettyunits
# Version          : 1.2.0
# Source repo      : https://github.com/cran/prettyunits
# Tested on	: UBI:9.3
# Language      : R
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Shubham Garud <Shubham.Garud@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=prettyunits
PACKAGE_VERSION=${1:-1.2.0}
PACKAGE_URL=https://github.com/cran/prettyunits

dnf install -y gcc gcc-c++ gcc-gfortran git wget xz cmake make openssl-devel yum-utils wget sudo llvm -y
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os/


wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official


#install R

dnf install --nodocs -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
dnf install -y libtirpc.ppc64le
dnf install -y R-core R-core-devel
dnf builddep R -y
R --version


git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION
cd ..

if ! R -e "install.packages('$PACKAGE_NAME', dependencies = TRUE, repos = 'http://cran.rstudio.com/')";then
    echo "------------------$PACKAGE_NAME:Dependencies installation fail-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#Note: vignettes are disabled
#Refer to https://r-pkgs.org/vignettes.html

if ! R CMD build $PACKAGE_NAME --no-build-vignettes; then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  build_Fails"
    exit 1
fi


if ! R CMD INSTALL $PACKAGE_NAME; then
    echo "------------------$PACKAGE_NAME:install_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi


if ! R CMD check $PACKAGE_NAME --no-build-vignettes --ignore-vignettes --no-manual; then
    echo "------------------$PACKAGE_NAME:install_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
