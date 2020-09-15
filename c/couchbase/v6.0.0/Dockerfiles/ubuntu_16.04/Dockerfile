FROM ubuntu:16.04
MAINTAINER "Priya Seth <sethp@us.ibm.com>"

ENV WDIR=/root
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-ppc64el
ENV PATH=$WDIR/depot_tools:$WDIR/couchbase:$PATH
ENV VPYTHON_BYPASS="manually managed python not supported by chrome operations"
ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

COPY crc-files.tar.gz /tmp/crc-files.tar.gz
COPY patch-files.tar.gz /tmp/patch-files.tar.gz
WORKDIR /root

RUN apt-get update -y && \
    apt-get install -y wget git g++ make curl libssl-dev libevent-dev \
        libcurl4-openssl-dev libsnappy-dev ncurses-dev openssl libiodbc2-dev \
        autoconf cmake libtool python python-dev golang-go subversion cmake \
        gnupg openjdk-8-jdk openjdk-8-jre lsb-release && \

    cd $WDIR && \
        svn export http://source.icu-project.org/repos/icu/tags/release-58-1 icu && \
        cd icu/icu4c/source && \
        ./configure --enable-static --disable-renaming --prefix=/usr && \
        make && \
        make install && \
        cp /usr/lib/libicu* /usr/local/lib && \
        cd $WDIR && \
        rm -rf icu && \

    cd $WDIR && \
        git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git && \
        cd $WDIR && \
        fetch v8 && \
        cd v8 && \
        git checkout 5.8.75 && \
        gclient sync && \
        python gypfiles/gyp_v8 && \
        make -j4 ppc64.release -i werror=no GYPFLAGS+="-Dcomponent=shared_library -Dv8_enable_i18n_support=0" && \
        make -j4 ppc64.release library=shared -i werror=no GYPFLAGS+="-Dcomponent=shared_library -Dv8_enable_i18n_support=0" && \
        cp -vR include/* /usr/include && \
        cp -v out/ppc64.release/lib.target/lib*.so /usr/local/lib && \
        cp /usr/local/lib/libv8.so /usr/lib && \

    cd $WDIR && \
        git clone https://github.com/google/flatbuffers && \
        cd flatbuffers && \
        cmake -G "Unix Makefiles" && \
        make && \
        export PATH=$PATH:`pwd` && \
        make install && \
        cd .. && \
        rm -rf flatbuffers && \

    mkdir -p ~/.cbdepscache/exploded/ppc64le && \
        wget https://dl.google.com/go/go1.7.6.linux-ppc64le.tar.gz && \
        tar -xzf go1.7.6.linux-ppc64le.tar.gz && \
        mkdir ~/.cbdepscache/exploded/ppc64le/go-1.7.6 && \
        mv go ~/.cbdepscache/exploded/ppc64le/go-1.7.6 && \
        ln -s ~/.cbdepscache/exploded/ppc64le/go-1.7.6 ~/.cbdepscache/exploded/ppc64le/go-1.7.3 && \
        rm go1.7.6.linux-ppc64le.tar.gz && \

    wget https://dl.google.com/go/go1.8.1.linux-ppc64le.tar.gz && \
        tar -xzf go1.8.1.linux-ppc64le.tar.gz && \
        mkdir ~/.cbdepscache/exploded/ppc64le/go-1.8.1 && \
        mv go ~/.cbdepscache/exploded/ppc64le/go-1.8.1 && \
        rm go1.8.1.linux-ppc64le.tar.gz && \

    wget https://dl.google.com/go/go1.8.5.linux-ppc64le.tar.gz && \
        tar -xzf go1.8.5.linux-ppc64le.tar.gz && \
        mkdir ~/.cbdepscache/exploded/ppc64le/go-1.8.5 && \
        mv go ~/.cbdepscache/exploded/ppc64le/go-1.8.5 && \
        ln -s ~/.cbdepscache/exploded/ppc64le/go-1.8.5 ~/.cbdepscache/exploded/ppc64le/go-1.8.3 && \
        rm go1.8.5.linux-ppc64le.tar.gz && \

    wget https://dl.google.com/go/go1.9.6.linux-ppc64le.tar.gz && \
        tar -xzf go1.9.6.linux-ppc64le.tar.gz && \
        mkdir ~/.cbdepscache/exploded/ppc64le/go-1.9.6 && \
        mv go ~/.cbdepscache/exploded/ppc64le/go-1.9.6 && \
        rm go1.9.6.linux-ppc64le.tar.gz && \

    cd $WDIR && \
        mkdir couchbase && \
        curl https://storage.googleapis.com/git-repo-downloads/repo > couchbase/repo && \
        chmod a+x couchbase/repo && \
        cd couchbase && \
        repo init -u git://github.com/couchbase/manifest.git -m released/6.0.0.xml && \
        repo sync && \

    cd godeps/src/github.com && \
        mv boltdb boltdb_ORIG && \
        mkdir boltdb && \
        cd boltdb && \
        git clone https://github.com/boltdb/bolt.git && \
        cd bolt && \
        git tag -l && \
        git checkout v1.3.0 && \
        cd ../.. && \
        cd ../../.. && \

    tar -xzf /tmp/crc-files.tar.gz -C /tmp && \
        mv /tmp/crc-files/crc32_constants.h platform/include/platform/crc32_constants.h && \
        mv /tmp/crc-files/crc32_wrapper.c platform/src/crc32_wrapper.c && \
        mv /tmp/crc-files/crc32.S platform/src/crc32.S && \
        mv /tmp/crc-files/ppc-opcode.h platform/include/platform/ppc-opcode.h && \
        rmdir /tmp/crc-files && \

    tar -xzf /tmp/patch-files.tar.gz -C /tmp && \
	mv /tmp/patch-files/tlm.patch tlm && cd tlm && git apply < tlm.patch && cd .. &&  \
	mv /tmp/patch-files/platform.patch platform && cd platform && git apply < platform.patch && cd .. && \
	mv /tmp/patch-files/forestdb.patch forestdb && cd forestdb && git apply < forestdb.patch && cd .. && \
	mv /tmp/patch-files/kv_engine.patch kv_engine && cd kv_engine && git apply < kv_engine.patch && cd .. && \
        mv /tmp/patch-files/skiplist.patch goproj/src/github.com/couchbase/indexing/secondary/memdb/skiplist && \
		cd goproj/src/github.com/couchbase/indexing/secondary/memdb/skiplist && \
		git apply < skiplist.patch && cd $WDIR/couchbase && \
        mv /tmp/patch-files/benchmark.patch benchmark && cd benchmark && \
		git apply < benchmark.patch && cd .. && \
	mv /tmp/patch-files/CMakeLists.patch . && patch < CMakeLists.patch && \
	
    cd tlm/deps/packages && \
    mkdir build-boost && \
        cd build-boost && \
        cmake .. -DPACKAGE=boost && \
        cmake --build . --target boost && \
        t_filename=`ls deps/boost/*/boost*.tgz` && \
        m_filename=`ls deps/boost/*/boost*.md5` && \
        cp $t_filename ~/.cbdepscache && \
        cp $m_filename ~/.cbdepscache/`basename $t_filename`.md5 && \
        cd .. && \
        rm -rf build-boost && \

    mkdir build-curl && \
        cd build-curl && \
        cmake .. -DPACKAGE=curl && \
        cmake --build . --target curl && \
        t_filename=`ls deps/curl/*/curl*.tgz` && \
        m_filename=`ls deps/curl/*/curl*.md5` && \
        cp $t_filename ~/.cbdepscache && \
        cp $m_filename ~/.cbdepscache/`basename $t_filename`.md5 && \
        cd .. && \
        rm -rf build-curl && \

    mkdir build-flatbuffers && \
        cd build-flatbuffers && \
        cmake .. -DPACKAGE=flatbuffers && \
        cmake --build . --target flatbuffers && \
        t_filename=`ls deps/flatbuffers/*/flatbuffers*.tgz` && \
        m_filename=`ls deps/flatbuffers/*/flatbuffers*.md5` && \
        cp $t_filename ~/.cbdepscache && \
        cp $m_filename ~/.cbdepscache/`basename $t_filename`.md5 && \
        cd .. && \
        rm -rf build-flatbuffers && \

    mkdir build-icu4c && \
        cd build-icu4c && \
        cmake .. -DPACKAGE=icu4c && \
        cmake --build . --target icu4c && \
        t_filename=`ls deps/icu4c/*/icu4c*.tgz` && \
        m_filename=`ls deps/icu4c/*/icu4c*.md5` && \
        cp $t_filename ~/.cbdepscache && \
        cp $m_filename ~/.cbdepscache/`basename $t_filename`.md5 && \
        cd .. && \
        rm -rf build-icu4c && \

    mkdir build-jemalloc && \
        cd build-jemalloc && \
        cmake .. -DPACKAGE=jemalloc && \
        cmake --build . --target jemalloc && \
        t_filename=`ls deps/jemalloc/*/jemalloc*.tgz` && \
        m_filename=`ls deps/jemalloc/*/jemalloc*.md5` && \
        cp $t_filename ~/.cbdepscache && \
        cp $m_filename ~/.cbdepscache/`basename $t_filename`.md5 && \
        cd .. && \
        rm -rf build-jemalloc && \

    mkdir build-json && \
        cd build-json && \
        cmake .. -DPACKAGE=json && \
        cmake --build . --target json && \
        t_filename=`ls deps/json/*/json*.tgz` && \
        m_filename=`ls deps/json/*/json*.md5` && \
        cp $t_filename ~/.cbdepscache && \
        cp $m_filename ~/.cbdepscache/`basename $t_filename`.md5 && \
        cd .. && \
        rm -rf build-json && \

    mkdir build-libcouchbase && \
        cd build-libcouchbase && \
        cmake .. -DPACKAGE=libcouchbase && \
        cmake --build . --target libcouchbase && \
        t_filename=`ls deps/libcouchbase/*/libcouchbase*.tgz` && \
        m_filename=`ls deps/libcouchbase/*/libcouchbase*.md5` && \
        cp $t_filename ~/.cbdepscache && \
        cp $m_filename ~/.cbdepscache/`basename $t_filename`.md5 && \
        cd .. && \
        rm -rf build-libcouchbase && \

    mkdir build-libevent && \
        cd build-libevent && \
        cmake .. -DPACKAGE=libevent && \
        cmake --build . --target libevent && \
        t_filename=`ls deps/libevent/*/libevent*.tgz` && \
        m_filename=`ls deps/libevent/*/libevent*.md5` && \
        cp $t_filename ~/.cbdepscache && \
        cp $m_filename ~/.cbdepscache/`basename $t_filename`.md5 && \
        cd .. && \
        rm -rf build-libevent && \

    mkdir build-snappy && \
        cd build-snappy && \
        cmake .. -DPACKAGE=snappy && \
        cmake --build . --target snappy && \
        t_filename=`ls deps/snappy/*/snappy*.tgz` && \
        m_filename=`ls deps/snappy/*/snappy*.md5` && \
        cp $t_filename ~/.cbdepscache && \
        cp $m_filename ~/.cbdepscache/`basename $t_filename`.md5 && \
        cd .. && \
        rm -rf build-snappy && \

    mkdir build-python-snappy && \
        cd build-python-snappy && \
        cmake .. -DPACKAGE=python-snappy && \
        cmake --build . --target python-snappy && \
        t_filename=`ls deps/python-snappy/*/python-snappy*.tgz` && \
        m_filename=`ls deps/python-snappy/*/python-snappy*.md5` && \
        cp $t_filename ~/.cbdepscache && \
        cp $m_filename ~/.cbdepscache/`basename $t_filename`.md5 && \
        cd .. && \
        rm -rf build-python-snappy && \

    mkdir build-flex && \
        cd build-flex && \
	cmake .. -DPACKAGE=flex && \
        cmake --build . --target flex && \
        t_filename=`ls deps/flex/*/flex*.tgz` && \
        m_filename=`ls deps/flex/*/flex*.md5` && \
        cp $t_filename ~/.cbdepscache && \
        cp $m_filename ~/.cbdepscache/`basename $t_filename`.md5 && \
        cd .. && \
        rm -rf build-flex && \

    mkdir build-libuv && \
        cd build-libuv && \
	cmake .. -DPACKAGE=libuv && \
        cmake --build . --target libuv && \
        t_filename=`ls deps/libuv/*/libuv*.tgz` && \
        m_filename=`ls deps/libuv/*/libuv*.md5` && \
        cp $t_filename ~/.cbdepscache && \
        cp $m_filename ~/.cbdepscache/`basename $t_filename`.md5 && \
        cd .. && \
        rm -rf build-libuv && \

    mkdir build-lz4 && \
        cd build-lz4 && \
	cmake .. -DPACKAGE=lz4 && \
        cmake --build . --target lz4 && \
        t_filename=`ls deps/lz4/*/lz4*.tgz` && \
        m_filename=`ls deps/lz4/*/lz4*.md5` && \
        cp $t_filename ~/.cbdepscache && \
        cp $m_filename ~/.cbdepscache/`basename $t_filename`.md5 && \
        cd .. && \
        rm -rf build-lz4 && \

    mkdir build-maven && \
        cd build-maven && \
	cmake .. -DPACKAGE=maven && \
        cmake --build . --target maven && \
        t_filename=`ls deps/maven/*/maven*.tgz` && \
        m_filename=`ls deps/maven/*/maven*.md5` && \
        cp $t_filename ~/.cbdepscache && \
        cp $m_filename ~/.cbdepscache/`basename $t_filename`.md5 && \
        cd .. && \
        rm -rf build-maven && \

    mkdir build-numactl && \
        cd build-numactl && \
	cmake .. -DPACKAGE=numactl && \
        cmake --build . --target numactl && \
        t_filename=`ls deps/numactl/*/numactl*.tgz` && \
        m_filename=`ls deps/numactl/*/numactl*.md5` && \
        cp $t_filename ~/.cbdepscache && \
        cp $m_filename ~/.cbdepscache/`basename $t_filename`.md5 && \
        cd .. && \
        rm -rf build-numactl && \

    mkdir build-zlib && \
        cd build-zlib && \
        cmake .. -DPACKAGE=zlib && \
        cmake --build . --target zlib && \
        t_filename=`ls deps/zlib/*/zlib*.tgz` && \
        m_filename=`ls deps/zlib/*/zlib*.md5` && \
        cp $t_filename ~/.cbdepscache && \
        cp $m_filename ~/.cbdepscache/`basename $t_filename`.md5 && \
        cd .. && \
        rm -rf build-zlib && \

    mkdir build-erlang && \
	cd build-erlang && \
	cmake .. -DPACKAGE=erlang && \
	cmake --build . --target erlang && \
	t_filename=`ls deps/erlang/*/erlang*.tgz` && \
	m_filename=`ls deps/erlang/*/erlang*.md5` && \
	cp $t_filename ~/.cbdepscache && \
	cp $m_filename ~/.cbdepscache/`basename $t_filename`.md5 && \
	cd .. && \
	rm -rf build-erlang && \
	cd ../../.. && \

    echo "------- starting couchbase build -------" && \
        cd $WDIR && \
	mkdir build && \
	cd build && \
	cmake -D CMAKE_BUILD_TYPE=Debug ../couchbase && \
	make all && \
        make install && \
        cd .. && \
        mv couchbase/install . && \
        rm -rf couchbase && \
        mkdir couchbase && mv install couchbase && \
        rm -rf depot_tools v8 build .cbdepscache && \

    apt-get remove -y wget git make curl autoconf cmake libtool \
        subversion cmake lsb-release && \
        apt-get autoremove -y

WORKDIR $WDIR/couchbase/install/bin

CMD [ "/bin/bash" ]
