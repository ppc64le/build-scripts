PACKAGE_NAME="grafana"
PACKAGE_URL="https://github.com/grafana/grafana.git"
PACKAGE_VERSION=v10.1.1
NODE_VERSION=${NODE_VERSION:-18}
GO_VERSION=1.20.6

yum install wget git curl make gcc-c++ python38 -y 

#install nodejs
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install $NODE_VERSION
npm install -g yarn

#install go
wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz && \
tar -C /usr/local -xzf go$GO_VERSION.linux-ppc64le.tar.gz && \
rm -rf go$GO_VERSION.linux-ppc64le.tar.gz
export GOROOT=/usr/local/go && \
export GOPATH=$HOME && \
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Apply patch
wget https://raw.githubusercontent.com/vinodk99/build-scripts/grafana_v10.1.1/g/grafana/grafana.patch
git apply grafana.patch

#Build frontend
yarn install
mkdir plugins-bundled/external
export NODE_OPTIONS="--max-old-space-size=8192"
make build-js

#Build backend
make gen-go
make deps-go
make build-go

#Test backend
make test-go

#Test backend
yarn test --watchAll=false
