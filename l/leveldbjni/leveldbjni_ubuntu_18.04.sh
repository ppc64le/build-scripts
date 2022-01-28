# ----------------------------------------------------------------------------
#
# Package          : leveldbjni
# Version          : 1.8
# Source repo      : https://github.com/fusesource/leveldbjni
# Tested on        : ubuntu_18.04
# Passing Arguments: 1.Version of package
# Script License   : Apache License, Version 2 or later
# Maintainer       : Arumugam N S <asellappen@yahoo.com> / Priya Seth<sethp@us.ibm.com>
#
# Disclaimer       : This script has been tested in non-root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

export REPO=https://github.com/fusesource/leveldbjni

if [ -z "$1" ]; then
  export VERSION="leveldbjni-1.8"
else
  export VERSION="$1"
fi



sudo apt-get update
sudo apt-get install wget git make -y
sudo apt install build-essential -y

if [ -d "leveldbjni" ] ; then
  rm -rf leveldbjni
fi


git clone ${REPO}


## Build and test leveldbjni
cd leveldbjni
git checkout ${VERSION}
ret=$?

if [ $ret -eq 0 ] ; then
  echo "$Version found to checkout "
else
  echo "$Version not found "
  exit
fi

#support version change
sed 's/>1.5</>1.8</g' pom.xml >tmp
mv tmp pom.xml

##dependancy install
wget http://repository.timesys.com/buildsources/s/snappy/snappy-1.0.5/snappy-1.0.5.tar.gz
tar -zxvf snappy-1.0.5.tar.gz
git clone git://github.com/chirino/leveldb.git


export SNAPPY_HOME=`cd snappy-1.0.5; pwd`
export LEVELDB_HOME=`cd leveldb; pwd`
export LEVELDBJNI_HOME=`cd leveldbjni; pwd`

cd ${SNAPPY_HOME}
./configure --build ppc64le --disable-shared --with-pic
make


cd ${LEVELDB_HOME}
export LIBRARY_PATH=${SNAPPY_HOME}
export C_INCLUDE_PATH=${LIBRARY_PATH}
export CPLUS_INCLUDE_PATH=${LIBRARY_PATH}
git apply ../leveldb.patch
make libleveldb.a


# run tests with java 8
sudo apt-get install openjdk-8-jdk -y
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-ppc64el/
sudo apt install  -y maven



cd ${LEVELDBJNI_HOME}
cd ..
mvn clean install -P download -P all
