# -----------------------------------------------------------------------------
#
# Package	: github.com/golang/geo
# Version	: v0.0.0-20210211234256-740aa86cb551
# Source repo	: https://github.com/golang/geo
# Tested on	: UBI 8.6
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Siddesh Sangodkar <siddesh226@gmail.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=github.com/golang/geo
PACKAGE_VERSION=v0.0.0-20210211234256-740aa86cb551
PACKAGE_URL=https://github.com/golang/geo
COMMIT_ID=740aa86cb551d6388f5cf4a8f39568d52fac6ed7
CURDIR="$(pwd)"

yum install -y git wget golang

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

# set GOPATH
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$PATH


# Install geo 
mkdir -p $GOPATH/src/github.com/golang/
cd $GOPATH/src/github.com/golang/
git clone $PACKAGE_URL.git
cd geo
git checkout $COMMIT_ID

#add testcase patch
sed -i '71d' r3/vector.go
sed -i "71i func (v Vector) Dot(ov Vector) float64 { return float64(v.X*ov.X) + float64(v.Y*ov.Y) + float64(v.Z*ov.Z) }"  r3/vector.go
sed -i '76d' r3/vector.go
sed -i "76i float64(v.Y*ov.Z) - float64(v.Z*ov.Y),"  r3/vector.go
sed -i '77d' r3/vector.go
sed -i "77i float64(v.Z*ov.X) - float64(v.X*ov.Z),"  r3/vector.go
sed -i '78d' r3/vector.go
sed -i "78i float64(v.X*ov.Y) - float64(v.Y*ov.X),"  r3/vector.go

cd $GOPATH/src/$PACKAGE_NAME
if ! go mod tidy ; then
        echo "------------------$PACKAGE_NAME:initialize_fails-------------------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Initialize_Fails"
        exit 1
fi

if ! go test ./... ; then
        echo "------------------$PACKAGE_NAME:test_fails---------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Test_Fails"
        exit 1
else
        echo "------------------$PACKAGE_NAME:install_and_test_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass |  Install_and_Test_Success"
        exit 0
fi
