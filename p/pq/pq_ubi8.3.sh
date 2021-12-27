# -----------------------------------------------------------------------------
#
# Package       : "pq"
# Version       : v1.8.0
# Source repo   : https://github.com/lib/pq
# Tested on     : UBI 8.3
# Script License: Apache License, Version 2 or later
# Maintainer: Priya Seth<sethp@us.ibm.com> Adilhusain Shaikh <Adilhusain.Shaikh@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
#notes: start the container with the command: docker run  --privileged -dit registry.access.redhat.com/ubi8:8.3 /usr/sbin/init
# ----------------------------------------------------------------------------

PACKAGE_NAME="pq"
PACKAGE_VERSION=${1:-v1.8.0}
PACKAGE_URL="https://github.com/lib/pq"
OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

# go variables
export GO_VERSION=${GO_VERSION:-1.16}
export GOROOT=${GOROOT:-/usr/local/go}
export GOPATH=${GOPATH:-$HOME/go}
export PACKAGE_SOURCE_ROOT=$(awk -F '/' '{print  "/src/" $3 "/" $4;}' <<<$PACKAGE_URL | xargs printf "%s" $GOPATH)
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin

# steps to clean up the PKG installation
if [ "$1" = "clean" ]; then
    rm -rf $GOROOT
    rm -rf $GOPATH
    docker rm -f postgres
    exit 0
fi

echo "installing dependencies from system repo..."
dnf install wget git -y gcc gcc-c++ >/dev/null
wget https://oplab9.parqtec.unicamp.br/pub/repository/rpm/open-power-unicamp.repo
mv open-power-unicamp.repo /etc/yum.repos.d/
echo "installing docker..."
yum -y update >/dev/null
yum -y install docker-ce >/dev/null

# installing golang
wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz
tar -C /usr/local/ -xzf go$GO_VERSION.linux-ppc64le.tar.gz
rm -f go$GO_VERSION.linux-ppc64le.tar.gz

mkdir -p $PACKAGE_SOURCE_ROOT && cd $PACKAGE_SOURCE_ROOT
echo "cloning$PACKAGE_NAME $PACKAGE_VERSION at $PWD"
git clone -q $PACKAGE_URL $PACKAGE_NAME || exit 1
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION || exit 1

#create go.mod if it doesn't exist
if [[ $(echo "$GO_VERSION 1.11" | awk '{print ($1 >= $2)}') == 1 ]]; then
    go mod init
fi

go get golang.org/x/tools/cmd/goimports
go get golang.org/x/lint/golint
go get honnef.co/go/tools/cmd/staticcheck@2020.1.3

## testing
# start the docker service
systemctl start docker || {
    echo "can't start the docker !"
    echo "start the container with the command:  "
    echo "docker run  --privileged -dit registry.access.redhat.com/ubi8:8.3 /usr/sbin/init"

    exit 1
}

#declaring variable for postgres
export PGPASSWORD=1234
export PGHOST=localhost
export PGPORT=5400
export PGUSER=postgres
export PGSSLMODE=disable
export PGDATABASE=postgres

export TRYCOUNT=1
export TRYINTERVAL=${TRYINTERVAL:-5}
export MAXTRYCOUNT=10

docker run -d -p $PGPORT:5432 --name postgres -e POSTGRES_PASSWORD=1234 -t postgres

#checking if postgres container accepts request at $PGHOST:$PGPORT
# where  return code 52 means server has returned empty reply and it is accepting the request

while [[ $TRYCOUNT -le $MAXTRYCOUNT ]]; do
    echo "connecting to postgres container: " $TRYCOUNT
    curl ${PGHOST}:${PGPORT} &>/dev/null
    [[ $? -eq 52 ]] && break
    sleep $TRYINTERVAL
    ((TRYCOUNT++))
done

curl $PGHOST:$PGPORT &>/dev/null
[[ $? -ne 52 ]] && {
    echo "can't connect to postgres container!"
    exit 1
}

docker exec --user postgres postgres psql -c "create database ptest;"

if ! go test; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
