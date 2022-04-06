#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : gonum
# Version       : 4340aa3071a0
# Source repo   : https://github.com/gonum/gonum.git
# Tested on     : UBI 8.5
# Travis-Check  : True
# Language      : Go
# Script License: Apache License, Version 2 or later
# Maintainer    : saraswati patra <saraswati.patra@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=gonum
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=${1:-4340aa3071a0}
PACKAGE_URL=https://github.com/gonum/gonum.git
yum update -y
yum install -y vim cmake make git gcc-c++ perl
OS_NAME=`cat /etc/os-release | grep PRETTY_NAME | cut -d '=' -f2 | tr -d '"'`
HOME_DIR=`pwd`

if [ -d "$PACKAGE_NAME" ] ; then
  rm -rf $PACKAGE_NAME
  echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Removed existing package if any"  
fi

# Dependency installation
yum module install -y go-toolset
dnf install -y git

# Download the repos

if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
    exit 1
fi

# Build and Test yaml
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

export GO111MODULE="auto"

if ! go get -v -t ./...; then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_NAME  |  $PACKAGE_VERSION |  $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
fi

if ! go test -v ./...; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" 
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
	exit 0
fi

#build_success test in parity 

#3 test case fail due to below error.

#        cb: 13806701373219750527, nb: 13806701348765483035
#    amos_test.go:497: Case zseri yi_idx_2: Float64 mismatch. c = 0.00813340543351962, native = 0.00813341306156214
#         cb: 4575842210796048912, nb: 4575842215193316042
#--- FAIL: TestZseri (5.26s)

#=== RUN   TestBFGS
#    unconstrained_test.go:1199: Case 31: error finding minimum (linesearch: no change in location after Linesearcher step) for:
#       F: BrownBadlyScaled
#        Dim: 2
#        Initial X: [1 1]
#        GradientThreshold: 1e-12
#    unconstrained_test.go:1199: Case 32: error finding minimum (linesearch: no change in location after Linesearcher step) for:
#        F: BrownBadlyScaled
#        Dim: 2
#        Initial X: [1.000001e+06 2.01e-06]
#        GradientThreshold: 1e-12
#    unconstrained_test.go:1199: Case 51: error finding minimum (linesearch: no change in location after Linesearcher step) for:
#        F: PowellBadlyScaled
#        Dim: 2
#        Initial X: [0 1]
#        GradientThreshold: 1e-12
#    unconstrained_test.go:1199: Case 60: error finding minimum (linesearch: failed to converge) for:
#        F: BrownAndDennis
#        Dim: 4
#        Initial X: [25 5 -5 -1]
#        GradientThreshold: 1e-05
#    unconstrained_test.go:1199: Case 61: error finding minimum (linesearch: failed to converge) for:
#        F: ExtendedRosenbrock
#        Dim: 2
#        Initial X: [100000 100000]
#        GradientThreshold: 1e-10
#--- FAIL: TestBFGS (0.36s)
#=== RUN   TestNewton
#    unconstrained_test.go:1199: Case 2: error finding minimum (linesearch: no change in location after Linesearcher step) for:
#        F: BrownBadlyScaled
#        Dim: 2
#        Initial X: [1 1]
#        GradientThreshold: 1e-12
#--- FAIL: TestNewton (0.08s)
#=== RUN   TestTorgersonScaling
#    mds_test.go:121: unexpected k for test 0: got:5 want:4
#    mds_test.go:124: unexpected result for test 0:
#        got:
#        ⎡  208.32664   -369.53733    -80.54401     -7.07897     -0.00000⎤
#        ⎢ -904.84491    356.07447    -92.30954     19.07751     -0.00000⎥
#        ⎢  925.99407   1067.85886     38.58585      6.69670     -0.00000⎥
#        ⎢-1933.80351   1129.86099     50.09969     -7.34475     -0.00000⎥
#        ⎢ 1318.63331   -704.37590     56.67330     17.41925     -0.00000⎥
#        ⎢  858.39506   -319.59481    -24.18657    -18.13843     -0.00000⎥
#        ⎢-1591.65708  -1511.36882     43.30844     -1.04361     -0.00000⎥
#        ⎣ 1118.95642    351.08253      8.37285     -9.58770     -0.00000⎦
#        want:
#        ⎡ -208.32660    369.53730     80.54401      7.07897⎤
#        ⎢  904.84490   -356.07450     92.30954    -19.07751⎥
#        ⎢ -925.99410  -1067.85890    -38.58585     -6.69670⎥
#        ⎢ 1933.80350  -1129.86100    -50.09969      7.34475⎥
#        ⎢-1318.63330    704.37590    -56.67330    -17.41925⎥
#        ⎢ -858.39510    319.59480     24.18657     18.13843⎥
#        ⎢ 1591.65710   1511.36880    -43.30844      1.04361⎥
#        ⎣-1118.95640   -351.08250     -8.37285      9.58770⎦
#    mds_test.go:128: unexpected Eigenvalues for test 0:
#        got: [1.172027697614e+07 5.686036184502e+06 2.474981412369e+04 1.238300279584e+03 8.618313621868e-11 -2.471028925705e+02 -2.412961483428e+03 -8.452858567111e+04]
#        want:[1.172027697614e+07 5.686036184502e+06 2.474981412369e+04 1.238300279584e+03 -5.444455825182e-10 -2.471028925712e+02 -2.412961483429e+03 -8.452858567111e+04]
#--- FAIL: TestTorgersonScaling (0.00s)
#FAIL
#FAIL    gonum.org/v1/gonum/stat/mds     0.060s-->
#------------------gonum:install_success_but_test_fails---------------------
#gonum  |  4340aa3071a0 |  | GitHub | Fail |  Install_success_but_test_Fails
