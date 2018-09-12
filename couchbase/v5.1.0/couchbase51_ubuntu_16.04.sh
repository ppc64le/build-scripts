#!/bin/bash

apt-get update -y
apt-get install -y wget tar git g++ make curl libssl-dev libevent-dev \
     libcurl4-openssl-dev libsnappy-dev ncurses-dev openssl libiodbc2-dev \
     autoconf cmake libtool python python-dev golang-go subversion cmake \
     gnupg openjdk-8-jdk openjdk-8-jre lsb-release
apt-get update -y
apt-get upgrade -y

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-ppc64el
WDIR=`pwd`

# Build and install Erlang 17.4
echo " ------- building erlang ------- "
cd $WDIR
wget http://www.erlang.org/download/otp_src_17.4.tar.gz
tar zxvf otp_src_17.4.tar.gz
rm otp_src_17.4.tar.gz
ERL_TOP=$WDIR/otp_src_17.4
cd otp_src_17.4
./configure --build=ppc64le-unknown-linux-gnu --prefix=/usr
make
make install
cd ..
rm -rf otp_src_17.4
unset ERL_TOP

# Build and install ICU 58-1 (default does not work)
echo " ------- building icu ------- "
cd $WDIR
svn export http://source.icu-project.org/repos/icu/tags/release-58-1/ icu
cd icu/icu4c/source
./configure --enable-static --disable-renaming --prefix=/usr
make
make install
cp /usr/lib/libicu* /usr/local/lib
cd $WDIR
rm -rf icu

# Build and install V8
echo " ------- building v8 ------- "
cd $WDIR
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
export PATH=$WDIR/depot_tools:$PATH
export VPYTHON_BYPASS="manually managed python not supported by chrome operations"

cd $WDIR
fetch v8
cd v8
git checkout 5.8.75
gclient sync
python gypfiles/gyp_v8
# 
#rm -rf third_party/googletest/src buildtools/third_party/libunwind/trunk \
#  third_party/depot_tools test/wasm-js tools/luci-go third_party/proguard
#
make -j4 ppc64.release -i werror=no GYPFLAGS+="-Dcomponent=shared_library -Dv8_enable_i18n_support=0"
make -j4 ppc64.release library=shared -i werror=no GYPFLAGS+="-Dcomponent=shared_library -Dv8_enable_i18n_support=0"

#make -j$(cat /proc/cpuinfo | grep processor | wc -l) ppc64.release GYPFLAGS+="-Dcomponent=shared_library -Dv8_enable_backtrace=1 -Dv8_use_snapshot='true' -Dclang=0 -Dv8_use_external_startup_data=0 -Dv8_enable_i18n_support=0 -Dtest_isolation_mode=noop" PYTHONPATH=`pwd`/third_party/argparse-1.4.0 #(For RHEL, SLES (12, 12 SP1, 12 SP2), and Ubuntu only)
#make -j$(cat /proc/cpuinfo | grep processor | wc -l) ppc64.release GYPFLAGS+="-Dcomponent=shared_library -Dv8_enable_backtrace=1 -Dv8_use_snapshot='true' -Dclang=0 -Dv8_use_external_startup_data=0 -Dv8_enable_i18n_support=0 -Dtest_isolation_mode=noop" CC_host=/usr/bin/gcc-4.8 CXX_host=/usr/bin/g++-4.8 PYTHONPATH=`pwd`/third_party/argparse-1.4.0 #(For SLES 11 SP4 only)

cp -vR include/* /usr/include
cp -v out/ppc64.release/lib.target/lib*.so /usr/local/lib
cp /usr/local/lib/libv8.so /usr/lib
cp -v out/ppc64.release/obj.target/tools/gyp/lib*.a /usr/local/lib
export LD_LIBRARY_PATH=/usr/local/lib

# Install flatbuffers
echo " ------- building flatbuffers ------- "
cd $WDIR
git clone https://github.com/google/flatbuffers
cd flatbuffers
cmake -G "Unix Makefiles"
make
export PATH=$PATH:`pwd`
make install
cd ..
rm -rf flatbuffers

# Copy go compilers in .cbdepscache/exploded
echo " ------- installing go 1.7.6 ------- "
mkdir -p ~/.cbdepscache/exploded/ppc64le
wget https://dl.google.com/go/go1.7.6.linux-ppc64le.tar.gz
tar -xzf go1.7.6.linux-ppc64le.tar.gz
mkdir ~/.cbdepscache/exploded/ppc64le/go-1.7.6
mv go ~/.cbdepscache/exploded/ppc64le/go-1.7.6
ln -s ~/.cbdepscache/exploded/ppc64le/go-1.7.6 ~/.cbdepscache/exploded/ppc64le/go-1.7.3
rm go1.7.6.linux-ppc64le.tar.gz

echo " ------- installing go 1.8.1 ------- "
wget https://dl.google.com/go/go1.8.1.linux-ppc64le.tar.gz
tar -xzf go1.8.1.linux-ppc64le.tar.gz
mkdir ~/.cbdepscache/exploded/ppc64le/go-1.8.1
mv go ~/.cbdepscache/exploded/ppc64le/go-1.8.1
rm go1.8.1.linux-ppc64le.tar.gz

echo " ------- installing go 1.8.5 ------- "
wget https://dl.google.com/go/go1.8.5.linux-ppc64le.tar.gz
tar -xzf go1.8.5.linux-ppc64le.tar.gz
mkdir ~/.cbdepscache/exploded/ppc64le/go-1.8.5
mv go ~/.cbdepscache/exploded/ppc64le/go-1.8.5
ln -s ~/.cbdepscache/exploded/ppc64le/go-1.8.5 ~/.cbdepscache/exploded/ppc64le/go-1.8.3
rm go1.8.5.linux-ppc64le.tar.gz

echo "------- cloning source -------"
cd $WDIR
mkdir couchbase
export PATH=$WDIR/couchbase:$PATH
curl https://storage.googleapis.com/git-repo-downloads/repo > couchbase/repo
chmod a+x couchbase/repo
cd couchbase
repo init -u git://github.com/couchbase/manifest.git -m released/5.1.0.xml
repo sync

# Replace boltdb in couchbase sources
echo " ------- replacing boltdb ------- "
cd godeps/src/github.com
mv boltdb boltdb_ORIG
mkdir boltdb
cd boltdb
git clone https://github.com/boltdb/bolt.git
cd bolt
git tag -l
git checkout v1.3.0
cd ../..
cd ../../..

# apply patches, copy crc files.
echo "------- applying patch -------"
tar -xzf /tmp/crc-files.tar.gz -C /tmp
mv /tmp/crc-files/crc32_constants.h platform/include/platform/crc32_constants.h
mv /tmp/crc-files/crc32_wrapper.c platform/src/crc32_wrapper.c
mv /tmp/crc-files/crc32.S platform/src/crc32.S
mv /tmp/crc-files/ppc-opcode.h platform/include/platform/ppc-opcode.h
rmdir /tmp/crc-files
patch -p2 < /tmp/patch

# build couchbase
echo "------- building tlm deps -------"
cd tlm/deps/packages

echo "------- building boost -------"
mkdir build-boost
cd build-boost
cmake .. -DPACKAGE=boost
cmake --build . --target boost
t_filename=`ls deps/boost/*/boost*.tgz`
m_filename=`ls deps/boost/*/boost*.md5`
cp $t_filename ~/.cbdepscache
cp $m_filename ~/.cbdepscache/`basename $t_filename`.md5
cd ..
rm -rf build-boost

echo "------- building curl -------"
mkdir build-curl
cd build-curl
cmake .. -DPACKAGE=curl
cmake --build . --target curl
t_filename=`ls deps/curl/*/curl*.tgz`
m_filename=`ls deps/curl/*/curl*.md5`
cp $t_filename ~/.cbdepscache
cp $m_filename ~/.cbdepscache/`basename $t_filename`.md5
cd ..
rm -rf build-curl

echo "------- building erlang -------"
mkdir build-erlang
cd build-erlang
cmake .. -DPACKAGE=erlang
cmake --build . --target erlang
t_filename=`ls deps/erlang/*/erlang*.tgz`
m_filename=`ls deps/erlang/*/erlang*.md5`
cp $t_filename ~/.cbdepscache
cp $m_filename ~/.cbdepscache/`basename $t_filename`.md5
cd ..
rm -rf build-erlang

echo "------- building flatbuffers -------"
mkdir build-flatbuffers
cd build-flatbuffers
cmake .. -DPACKAGE=flatbuffers
cmake --build . --target flatbuffers
t_filename=`ls deps/flatbuffers/*/flatbuffers*.tgz`
m_filename=`ls deps/flatbuffers/*/flatbuffers*.md5`
cp $t_filename ~/.cbdepscache
cp $m_filename ~/.cbdepscache/`basename $t_filename`.md5
cd ..

echo "------- building icu4c -------"
mkdir build-icu4c
cd build-icu4c
cmake .. -DPACKAGE=icu4c
cmake --build . --target icu4c
t_filename=`ls deps/icu4c/*/icu4c*.tgz`
m_filename=`ls deps/icu4c/*/icu4c*.md5`
cp $t_filename ~/.cbdepscache
cp $m_filename ~/.cbdepscache/`basename $t_filename`.md5
cd ..
rm -rf build-icu4c

echo "------- building jemalloc -------"
mkdir build-jemalloc
cd build-jemalloc
cmake .. -DPACKAGE=jemalloc
cmake --build . --target jemalloc
t_filename=`ls deps/jemalloc/*/jemalloc*.tgz`
m_filename=`ls deps/jemalloc/*/jemalloc*.md5`
cp $t_filename ~/.cbdepscache
cp $m_filename ~/.cbdepscache/`basename $t_filename`.md5
cd ..
rm -rf build-jemalloc

echo "------- building json -------"
mkdir build-json
cd build-json
cmake .. -DPACKAGE=json
cmake --build . --target json
t_filename=`ls deps/json/*/json*.tgz`
m_filename=`ls deps/json/*/json*.md5`
cp $t_filename ~/.cbdepscache
cp $m_filename ~/.cbdepscache/`basename $t_filename`.md5
cd ..
rm -rf build-json

echo "------- building libcouchbase -------"
mkdir build-libcouchbase
cd build-libcouchbase
cmake .. -DPACKAGE=libcouchbase
cmake --build . --target libcouchbase
t_filename=`ls deps/libcouchbase/*/libcouchbase*.tgz`
m_filename=`ls deps/libcouchbase/*/libcouchbase*.md5`
cp $t_filename ~/.cbdepscache
cp $m_filename ~/.cbdepscache/`basename $t_filename`.md5
cd ..
rm -rf build-libcouchbase

echo "------- building libevent -------"
mkdir build-libevent
cd build-libevent
cmake .. -DPACKAGE=libevent
cmake --build . --target libevent
t_filename=`ls deps/libevent/*/libevent*.tgz`
m_filename=`ls deps/libevent/*/libevent*.md5`
cp $t_filename ~/.cbdepscache
cp $m_filename ~/.cbdepscache/`basename $t_filename`.md5
cd ..
rm -rf build-libevent

echo "------- building snappy -------"
mkdir build-snappy
cd build-snappy
cmake .. -DPACKAGE=snappy
cmake --build . --target snappy
t_filename=`ls deps/snappy/*/snappy*.tgz`
m_filename=`ls deps/snappy/*/snappy*.md5`
cp $t_filename ~/.cbdepscache
cp $m_filename ~/.cbdepscache/`basename $t_filename`.md5
cd ..
rm -rf build-snappy

echo "------- building python-snappy -------"
mkdir build-python-snappy
cd build-python-snappy
cmake .. -DPACKAGE=python-snappy
cmake --build . --target python-snappy
t_filename=`ls deps/python-snappy/*/python-snappy*.tgz`
m_filename=`ls deps/python-snappy/*/python-snappy*.md5`
cp $t_filename ~/.cbdepscache
cp $m_filename ~/.cbdepscache/`basename $t_filename`.md5
cd ..
rm -rf build-python-snappy

echo "------- building rocksdb -------"
mkdir build-rocksdb
cd build-rocksdb
cmake .. -DPACKAGE=rocksdb
cmake --build . --target rocksdb
t_filename=`ls deps/rocksdb/*/rocksdb*.tgz`
m_filename=`ls deps/rocksdb/*/rocksdb*.md5`
cp $t_filename ~/.cbdepscache
cp $m_filename ~/.cbdepscache/`basename $t_filename`.md5
cd ..
rm -rf build-rocksdb
cd ../../..

echo "------- starting cb build -------"
cd ..
mkdir build
cd build
cmake -D CMAKE_BUILD_TYPE=Debug -DU_DISABLE_RENAMING=1 ../couchbase
make all

# build test binaries, which do not get built automatically.
echo "------- building test binaries -------"
make benchmark_test
make basic_test
make filter_test
make options_test
make atomic_test
make bcache_test
make bitset-test
make btreeblock_test
make btree_kv_test
make btree_str_kv_test
make compact_functional_test
make complexity_test
make couchstore_file-deduper-test
make couchstore_file-merger-test
make couchstore_file-sorter-test
make couchstore_gtest
make couchstore_internal_gtest
make couchstore_mapreduce-builtin-test
make couchstore_mapreduce-map-test
make couchstore_mapreduce-reduce-test
make couchstore_testapp
make couchstore_wrapped_fileops_test
make cxx03_test
make diagnostics_test
make disk_sim_test
make docio_test
make donotoptimize_test
make e2etest
make fdb_anomaly_test
make fdb_extended_test
make fdb_functional_test
make fdb_microbench
make filemgr_test
make fixture_test
make hash_test
make hbtrie_test
make iterator_functional_test
make map_test
make moxi_htgram_test
make moxi_sizes
make multi_kv_functional_test
make multiple_ranges_test
make mvcc_functional_test
make options_test
make platform-backtrace-test
make platform-base64-test
make platform-checked-snprintf-test
make platform-cjson-parse-test
make platform-cjsonutils-test
make platform-compression-test
make platform-crc32c-sw_hw-test
make platform-crc32c-test
make platform-dirutils-test
make platform-gethrtime-test
make platform-getopt-test
make platform-gettimeofday-test
make platform-histogram-test
make platform-json-checker-test
make platform-make_array-test
make platform-memorymap-test
make platform-mktemp-test
make platform-non_negative_counter-test
make platform-processclock-test
make platform-random-test
make platform-relaxed_atomic-test
make platform-strings-test
make platform-sysinfo-test
make platform-thread-test
make platform-uuid-test
make register_benchmark_test
make reporter_output_test
make ring-buffer-test
make cbcrypto_test
make cbsasl_client_server_test
make cbsasl_password_database_test
make cbsasl_pwconv_test
make cbsasl_saslprep_test
make cbsasl_server_test
make cbsasl_strcmp_test
make client_cert_config_test
make engine_testapp
make ep-engine_atomic_ptr_test
make ep-engine_couch-fs-stats_test
make ep-engine_ep_unit_tests
make ep-engine_hrtime_test
make ep-engine_misc_test
make mcbp_dump_parser_test
make memcached_auditconfig_test
make memcached_auditd_tests
make memcached_audit_evdescr_test
make memcached_auditfile_test
make memcached_config_parse_test
make memcached_config_util_test
make memcached_datatype_test
make memcached-doc-server-api-test
make memcached-engine-error-test
make memcached_errormap_sanity_check
make memcached_executor_test
make memcached_function_chain_test
make memcached-hostutils-test
make memcached_logger_emfile_test
make memcached_logger_test
make memcached_mcbp_test
make memcached_memory_tracking_test
make memcached_privilege_test
make memcached_sizes
make memcached_testapp
make memcached_timestamp_test
make memcached_topkeys_bench
make utilities_testapp
make macro_test
make memory_usage_test
make threaded_test
make category_registry_test
make chunk_lock_test
make export_test
make memory_test
make string_utils_test
make trace_argument_test
make trace_buffer_test
make trace_config_test
make trace_event_test
make trace_log_test
make platform_extmeta_test
make platform_pipe_benchmark
make platform_pipe_test
make subjson-test
make sized-buffer-test
make skip_with_error_test
make staleblock_test
make tests_check_kvpair
make t_sigar_cpu
make t_sigar_mem
make t_sigar_netconn
make t_sigar_pid
make t_sigar_proc
make t_sigar_swap
make usecase_test
make vbucket_regression
make vbucket_testapp
make vbucket_testketama
echo "------- Couchbase build completed -------"
echo "------- starting tests -------"
time ctest
cd ..
echo "------- tests completed -------"
