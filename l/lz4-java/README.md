Build/Test lz4-java
-------------------

LZ4 Java: LZ4 compression library for Java (https://github.com/lz4/lz4-java)

Step 1) Build lz4java_builder image (once per release)
        $ docker build -t lz4java_builder .

Step 2) Build/Test lz4java_builder

        Usage:
                $ docker run --rm -v `pwd`:/ws lz4java_builder bash -l -c "cd /ws; ./build.sh <rel_tag> 2>&1 | tee output.log"

        Examples:
                ==========
                Build Only
                ==========
                # build master by default or pass desired release_tag.
                $ docker run --rm -v `pwd`:/ws lz4java_builder bash -l -c "cd /ws; ./build.sh 2>&1 | tee output.log"

                # build specific branch/release.
                $ docker run --rm -v `pwd`:/ws lz4java_builder bash -l -c "cd /ws; ./build.sh 1.7.1 2>&1 | tee output.log"
