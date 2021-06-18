Build/Test rocksdb
------------------

RocksDB: A Persistent Key-Value Store for Flash and RAM Storage. It is a library that forms the core building block for a fast key-value
         server, especially suited for storing data on flash drives. (https://github.com/facebook/rocksdb)

Note: This needs to be run in a Power 8 environment

Step 1) Build rocksdb_builder image (once per release)
        $ docker build -t rocksdb_builder .

Step 2) Build/Test rocksdb_builder

        Usage:
                $ docker run --rm -v `pwd`:/ws rocksdb_builder bash -l -c "cd /ws; ./build.sh <rel_tag> <runtest> 2>&1 | tee output.log"

        Examples:
                ==========
                Build Only
                ==========
                # build master by default or pass desired release_tag. No tests
                $ docker run --rm -v `pwd`:/ws rocksdb_builder bash -l -c "cd /ws; ./build.sh 2>&1 | tee output.log"

                # build specific branch/release. No tests
                $ docker run --rm -v `pwd`:/ws rocksdb_builder bash -l -c "cd /ws; ./build.sh v5.18.4 2>&1 | tee output.log"


                ===============
                Build/Run Tests
                ===============
                # build master if no tag specified & run tests
                $ docker run --rm -v `pwd`:/ws rocksdb_builder bash -l -c "cd /ws; ./build.sh runtest 2>&1 | tee output.log"

                # build release "v5.18.4" and run tests
                $ docker run --rm -v `pwd`:/ws rocksdb_builder bash -l -c "cd /ws; ./build.sh v5.18.4 runtest 2>&1 | tee output.log"


# Note: Building on Power9
#	Issue: g++ 4.8.5 doesn't support mcpu=power9 as of Jun-2021
#	==> rocksdb/build_tools/build_detect_platform
#	As workaround, set "POWER=power8" in above file to build on P9
