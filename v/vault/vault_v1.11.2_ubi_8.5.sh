PACKAGE_NAME=vault
PACKAGE_VERSION=${1:-v1.11.2}
PACKAGE_URL=https://github.com/hashicorp/vault.git

yum install -y openssl sudo make git gcc wget

wget https://golang.org/dl/go1.17.12.linux-ppc64le.tar.gz
tar -C /usr/local -xvzf go1.17.12.linux-ppc64le.tar.gz
rm -rf go1.17.12.linux-ppc64le.tar.gz
export PATH=/usr/local/go/bin:$PATH

mkdir -p /go/src/github.com/hashicorp

export GOPATH=/go
export PATH=$PATH:$GOPATH/bin

cd /go/src/github.com/hashicorp
git clone $PACKAGE_URL
cd vault
git checkout $PACKAGE_VERSION

go mod init
make fmt
make bootstrap
go mod vendor
make

if ! make; then
	echo "------------------$PACKAGE_NAME:build_fails---------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Test_Fails"
else
	echo "------------------$PACKAGE_NAME:build_success-------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Install_and_Test_Success"
fi
