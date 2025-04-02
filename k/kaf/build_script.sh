PACKAGE_NAME=kaf
PACKAGE_VERSION=${1:-master}
PACKAGE_URL=https://github.com/birdayz/kaf.git

yum install -y git gcc wget
export GO_VERSION=${GO_VERSION:-1.23.4}
export GOROOT=${GOROOT:-"/usr/local/go"}
export GOPATH=${GOPATH:-$HOME/go}
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin:/usr/local/bin

wget https://golang.org/dl/go${GO_VERSION}.linux-ppc64le.tar.gz
tar -C /usr/local -xvzf go${GO_VERSION}.linux-ppc64le.tar.gz
rm -rf go${GO_VERSION}.linux-ppc64le.tar.gz

git clone $PACKAGE_URL $PACKAGE_NAME
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

go mod tidy

if ! go build -ldflags "-w -s" ./cmd/kaf; then
        echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
        exit 1
else
        echo "------------------$PACKAGE_NAME:build_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Build_Success"
fi

#Used '-race' instead of '-v' to avoid test failures due to the unavailability of the mysql image for ppc64le architecture, causing error
#FAIL    github.com/orlangure/gnomock
if ! go test -race ./...; then
        echo "------------------$PACKAGE_NAME:test_fails---------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Test_Fails"
        exit 2
else
        echo "------------------$PACKAGE_NAME:test_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Test_Success"
        exit 0
fi
