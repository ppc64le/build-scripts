#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : opentelemetry-python-contrib
# Version          : v1.16.0
# Source repo      : https://github.com/open-telemetry/opentelemetry-python-contrib
# Tested on        : UBI:9.6
# Language         : Python
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Ramnath Nayak <Ramnath.Nayak@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=opentelemetry-python-contrib
PACKAGE_VERSION=${1:-v1.16.0}
PACKAGE_URL=https://github.com/open-telemetry/opentelemetry-python-contrib
PACKAGE_DIR=opentelemetry-python-contrib

CURRENT_DIR=${PWD}

yum install -y git make cmake zip tar wget python3.12 python3.12-devel python3.12-pip python3-pip gcc-toolset-13 gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc zlib-devel libjpeg-devel openssl openssl-devel freetype-devel pkgconfig rust cargo diffutils libyaml-devel

source /opt/rh/gcc-toolset-13/enable

python3.12 -m pip install build tox
#python3.12 -m pip install --prefer-binary grpcio --extra-index-url=https://wheels.developerfirst.ibm.com/ppc64le/linux

cd $CURRENT_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

sed -i "/^\[tool.black\]/i [build-system]\\nrequires = [\\\"setuptools>=61.0\\\"]\\nbuild-backend = \\\"setuptools.build_meta\\\"\\n\\n[project]\\nname = \\\"opentelemetry-python-contrib\\\"\\nversion = \\\"${PACKAGE_VERSION}\\\"\\ndescription = \\\"OpenTelemetry Python Contrib\\\"\\nauthors = [{ name = \\\"OpenTelemetry Authors\\\", email = \\\"cncf-opentelemetry-contributors@lists.cncf.io\\\" }]\\nreadme = \\\"README.md\\\"\\nrequires-python = \\\">=3.7\\\"\\n\\n[tool.setuptools]\\npackages = [\\n  \\\"instrumentation\\\",\\n  \\\"exporter\\\",\\n  \\\"propagator\\\"\\n]\\n" pyproject.toml


#Build package
if ! ./scripts/build.sh ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#There are no proper tests for opentelemetry-python-contrib core package.



