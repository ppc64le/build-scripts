#!/bin/bash

sudo apt-get update -y
sudo apt-get install -y wget tar git g++ make curl libssl-dev libevent-dev \
     libcurl4-openssl-dev libsnappy-dev ncurses-dev openssl libiodbc2-dev \
	 cmake python sudo golang-go subversion cmake

WDIR=`pwd`

# Build and install Erlang 17.4
cd $WDIR
wget http://www.erlang.org/download/otp_src_17.4.tar.gz
tar zxvf otp_src_17.4.tar.gz
export ERL_TOP=$WDIR/otp_src_17.4
cd otp_src_17.4/ && ./configure --build=ppc64le-unknown-linux-gnu --prefix=/usr \
   && make && sudo make install

# Build and install V8
cd $WDIR
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
cd depot_tools
export PATH=$WDIR/depot_tools:$PATH
gclient
fetch v8
cd v8
gclient sync
python gypfiles/gyp_v8
sudo make -j4 ppc64.release -i werror=no
sudo make -j4 ppc64.release library=shared -i werror=no
sudo cp -vR include/* /usr/include/
sudo cp -v out/ppc64.release/lib.target/lib*.so /usr/local/lib/
sudo cp /usr/local/lib/libv8.so /usr/lib/
sudo cp -v out/ppc64.release/obj.target/tools/gyp/lib*.a /usr/local/lib/
export LD_LIBRARY_PATH=/usr/local/lib

# Build and install ICU 58-1 (default does not work)
cd $WDIR
svn export http://source.icu-project.org/repos/icu/tags/release-58-1/ icu
cd icu/icu4c/source && ./configure --enable-static --prefix=/usr \
   && make \
   && sudo make install
sudo cp /usr/lib/libicu* /usr/local/lib/

# Install flatbuffers
cd $WDIR
git clone https://github.com/google/flatbuffers
cd flatbuffers
cmake -G "Unix Makefiles" && make
export PATH=$PATH:`pwd`
sudo make install

# Sync couchbase repo
cd $WDIR
mkdir couchbase
export PATH=$WDIR/couchbase:$PATH
curl https://storage.googleapis.com/git-repo-downloads/repo > couchbase/repo
chmod a+x couchbase/repo
cd couchbase
repo init -u git://github.com/couchbase/manifest.git -m released/4.5.0.xml
repo sync

# Replace boltdb in couchbase sources
cd ./godeps/src/github.com/
mv boltdb boltdb_ORIG
mkdir boltdb
cd boltdb
git clone https://github.com/boltdb/bolt.git
cd bolt/
git tag -l && git checkout v1.3.0

# Copy and apply patches
# Assumes required files are copied already at $WDIR 
# forestdb: $WDIR/couchbase/forestdb
# indexing: $WDIR/couchbase/goproj/src/github.com/couchbase/indexing
# platform: $WDIR/couchbase/platform
cd $WDIR
cp couchbase_forestdb.patch couchbase/forestdb
cp couchbase_indexing.patch couchbase/goproj/src/github.com/couchbase/indexing 
cp couchbase_platform.patch couchbase/platform 

cd couchbase/

cd forestdb/
git apply couchbase_forestdb.patch
cd ../

cd goproj/src/github.com/couchbase/indexing
git apply couchbase_indexing.patch
cd ../../../../../

cd platform/
git apply couchbase_platform.patch
cd ../

#Build and test couchbase
make
cd build/ && ctest > ctest.log &
