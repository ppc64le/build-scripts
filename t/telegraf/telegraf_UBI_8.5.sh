PACKAGE_NAME=telegraf
PACKAGE_VERSION=${1:-v1.24.3}
PACKAGE_URL=https://github.com/influxdata/telegraf.git
GO_VERSION=${GO_VERSION:-1.19}

WORKDIR=`pwd`

#Install the required dependencies
yum update -y
yum install -y make git wget tar gcc-c++

cd $WORKDIR
wget https://golang.org/dl/go${GO_VERSION}.linux-ppc64le.tar.gz
tar -zxvf go${GO_VERSION}.linux-ppc64le.tar.gz

export GOPATH=$WORKDIR/go
export PATH=$PATH:$GOPATH/bin

#Clone and build the source
mkdir -p ${GOPATH}/src/github.com/influxdata
cd ${GOPATH}/src/github.com/influxdata
git clone $PACKAGE_URL
git checkout $PACKAGE_VERSION
cd $PACKAGE_NAME
make
make test
