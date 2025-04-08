PACKAGE_NAME=kcat
PACKAGE_VERSION=${1:-master}
PACKAGE_URL=https://github.com/edenhill/kcat.git

#Install all required dependencies
yum install -y git cmake openssl-devel cyrus-sasl-devel libcurl-devel jansson zlib-devel librdkafka yajl python3 g++ pkgconf-pkg-config krb5-devel


git clone $PACKAGE_URL 
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Build
if ! ./bootstrap.sh; then
        echo "------------------$PACKAGE_NAME:Build_fails-------------------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
	exit 1
else
        echo "------------------$PACKAGE_NAME:Build_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Build_Success"
fi
