Build/Test zstd-jni
-------------------
JNI bindings for Zstd native library that provides fast and high compression lossless algorithms
(https://github.com/luben/zstd-jni)

Step 1) Build zstd-jni-builder image (once per release)
        $ docker build -t zstd-jni-builder .

Step 2) Build/Test zstd-jni-builder

        Usage:
                $ docker run --rm -v `pwd`:/ws zstd-jni-builder bash -l -c "cd /ws; ./build.sh <rel_tag> 2>&1 | tee output.log"

        Examples:
                ==========
                Build Only
                ==========
                # build master by default
                $ docker run --rm -v `pwd`:/ws zstd-jni-builder bash -l -c "cd /ws; ./build.sh 2>&1 | tee output.log"

                # build specific branch/release
                $ docker run --rm -v `pwd`:/ws zstd-jni-builder bash -l -c "cd /ws; ./build.sh v1.5.0-2 2>&1 | tee output.log"
