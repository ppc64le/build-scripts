Build/Test apicast-operator-metadata
------------------------------------

Step 1) Build apicast-operator-metadata builder image (once per release)
        $ docker build -t apicast-operator-metadata-builder .

Step 2) Build/Test apicast-operator-metadata

        Usage:
                $ docker run --rm -v `pwd`:/ws apicast-operator-metadata-builder bash -l -c "cd /ws; ./build.sh <rel_tag> 2>&1 | tee output.log"

        Examples:
                ==========
                Build Only
                ==========
                # by default, build "lasttestedrelease" which is v0.3.1 marked as 'Latest_Release' as of Apr-30-2021
                # both the commands below build the "v0.3.1: branch
                $ docker run --rm -v `pwd`:/ws apicast-operator-metadata-builder bash -l -c "cd /ws; ./build.sh 2>&1 | tee output.log"
                $ docker run --rm -v `pwd`:/ws apicast-operator-metadata-builder bash -l -c "cd /ws; ./build.sh lasttestedrelease 2>&1 | tee output.log"

                # to build master branch
                $ docker run --rm -v `pwd`:/ws apicast-operator-metadata-builder bash -l -c "cd /ws; ./build.sh master 2>&1 | tee output.log"

                # build specific branch/release
                $ docker run --rm -v `pwd`:/ws apicast-operator-metadata-builder bash -l -c "cd /ws; ./build.sh v0.3.1 2>&1 | tee output.log"
