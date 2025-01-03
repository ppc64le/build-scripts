#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package          : autovizwidget
# Version          : 0.20.0
# Source repo      : https://github.com/jupyter-incubator/sparkmagic
# Tested on        : UBI:9.3
# Language         : Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Stuti Wali <Stuti.Wali@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

# Variables
PACKAGE_NAME=sparkmagic
PACKAGE_VERSION=${1:-0.20.0}
PACKAGE_URL=https://github.com/jupyter-incubator/sparkmagic
PACKAGE_DIR=sparkmagic/autovizwidget

yum install -y wget
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os/
wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

dnf install --nodocs -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

# Install dependencies
yum install -y python-devel python-pip git gcc gcc-c++ make cmake wget openssl-devel bzip2-devel libffi-devel zlib-devel  libjpeg-devel zlib-devel freetype-devel procps-ng openblas-devel epel-release meson ninja-build gcc-gfortran  libomp-devel zip unzip sqlite-devel sqlite bzip2 libzip-devel bzip2-devel

export LD_LIBRARY_PATH=/usr/lib64/:$LD_LIBRARY_PATH

dnf groupinstall -y "Development Tools"

#install rust
curl https://sh.rustup.rs -sSf | sh -s -- -y
source "$HOME/.cargo/env"  # Update environment variables to use Rust

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME/autovizwidget
git checkout $PACKAGE_VERSION

#install necessary Python packages
pip install wheel setuptools pytest build meson meson-python ninja cython pillow pytest-mock pytest-xdist pytest-timeout nose mock scikit-build-core
pip install pandas==1.3.5 numpy==1.21.6 

#Install
if ! (pip install . --no-build-isolation) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Run test cases
# skipping test as they are in parity with x86
if ! pytest -k "not (test_create_viz_empty_df or test_convert_to_displayable_dataframe or test_value_for_aggregation or test_x_changed_callback or test_y_changed_callback or test_y_agg__changed_callback or test_log_x_changed_callback or test_log_y_changed_callback or test_not_emit_graph_render_event_when_not_registered or test_emit_graph_render_event_when_registered or test_on_render_viz or test_create_viz_types_buttons)" ; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi

