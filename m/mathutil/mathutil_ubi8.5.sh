#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : mathutil
# Version       : v1.0.0
# Source repo   : https://gitlab.com/cznic/mathutil
# Tested on     : ubi 8.5
# Language      : GO
# Travis-Check  : True
# Script License: Apache License 2.0 ot later
# Maintainer    : Amit Mukati <amit.mukati3@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME="mathutil"
PACKAGE_VERSION=${1:-"v1.0.0"}
PACKAGE_URL="https://gitlab.com/cznic/mathutil"
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

export GO_VERSION=${GO_VERSION:-"1.17.4"}
export GOROOT=${GOROOT:-"/usr/local/go"}
export GOPATH=${GOPATH:-$HOME/go}
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin:/usr/local/bin
PACKAGE_SOURCE_ROOT=$(awk -F '/' '{print  "/src/" $3 "/" $4;}' <<<"$PACKAGE_URL" | xargs printf "%s" "$GOPATH")
export PACKAGE_SOURCE_ROOT

echo "installing dependencies from system repo"
dnf install -y wget git gcc-c++ >/dev/null

# installing golang
wget https://golang.org/dl/go"$GO_VERSION".linux-ppc64le.tar.gz
tar -C /usr/local/ -xzf go"$GO_VERSION".linux-ppc64le.tar.gz
rm -f go"$GO_VERSION".linux-ppc64le.tar.gz

if ! git clone "$PACKAGE_URL" "$PACKAGE_SOURCE_ROOT"/"$PACKAGE_NAME"; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
    exit 1
fi
cd "$PACKAGE_SOURCE_ROOT"/"$PACKAGE_NAME"
git checkout "$PACKAGE_VERSION" || exit 1
export GO111MODULE=on
go get modernc.org/mathutil
go get modernc.org/mathutil/mersenne
go mod init "$PACKAGE_NAME"
go mod tidy
if ! go build -v ./...; then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
    exit 1
fi

if ! go test -v ./...; then
    echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_success_but_test_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:build_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi

# test cases status
<<comment
--- PASS: TestQuadPolyFactors (2.29s)
=== RUN   TestFCPRNG
    all_test.go:5550: [43690 43691 43691]
--- PASS: TestFCPRNG (0.05s)
=== RUN   TestNewFloat
--- PASS: TestNewFloat (0.00s)
=== RUN   TestFloatDiv2
--- PASS: TestFloatDiv2 (0.00s)
=== RUN   TestFloatSqr
--- PASS: TestFloatSqr (0.00s)
=== RUN   TestFloatEq1
--- PASS: TestFloatEq1 (0.00s)
=== RUN   TestFloatGe2
--- PASS: TestFloatGe2 (0.00s)
=== RUN   TestFloatMaxFracBits
--- PASS: TestFloatMaxFracBits (0.00s)
=== RUN   TestBinaryLog
--- PASS: TestBinaryLog (0.00s)
=== RUN   TestMaxInt128
--- PASS: TestMaxInt128 (0.00s)
=== RUN   TestMinInt128
--- PASS: TestMinInt128 (0.00s)
=== RUN   TestInt128Add
--- PASS: TestInt128Add (0.00s)
=== RUN   TestInt128Add2
--- PASS: TestInt128Add2 (1.20s)
=== RUN   TestInt128BigInt
--- PASS: TestInt128BigInt (0.00s)
=== RUN   TestInt128BigInt2
--- PASS: TestInt128BigInt2 (1.25s)
=== RUN   TestInt128Cmp
--- PASS: TestInt128Cmp (0.00s)
=== RUN   TestInt128Cmp2
--- PASS: TestInt128Cmp2 (1.70s)
=== RUN   TestInt128Neg
--- PASS: TestInt128Neg (0.00s)
=== RUN   TestInt128Neg2
--- PASS: TestInt128Neg2 (1.29s)
=== RUN   TestInt128SetInt64
--- PASS: TestInt128SetInt64 (1.13s)
=== RUN   TestInt128SetUint64
--- PASS: TestInt128SetUint64 (1.04s)
=== RUN   ExampleBinaryLog
--- PASS: ExampleBinaryLog (0.00s)
PASS
ok      mathutil        (cached)
=== RUN   TestNew
--- PASS: TestNew (0.26s)
=== RUN   TestHasFactorUint32
--- PASS: TestHasFactorUint32 (0.00s)
=== RUN   TestHasFactorUint64
--- PASS: TestHasFactorUint64 (0.00s)
=== RUN   TestHasFactorBigInt
--- PASS: TestHasFactorBigInt (0.00s)
=== RUN   TestFromFactorBigInt
--- PASS: TestFromFactorBigInt (0.02s)
=== RUN   TestMod
--- PASS: TestMod (0.39s)
=== RUN   TestModPow
--- PASS: TestModPow (0.53s)
=== RUN   TestModPow2
--- PASS: TestModPow2 (0.00s)
PASS
ok      mathutil/mersenne       (cached)
------------------mathutil:build_&_test_both_success-------------------------
https://gitlab.com/cznic/mathutil mathutil
mathutil  |  https://gitlab.com/cznic/mathutil | v1.0.0 | "Red Hat Enterprise Linux 8.5 (Ootpa)" | GitHub  | Pass |  Both_Build_and_Test_Success
comment
