Build/Test 3scale-operator-metadata
-----------------------------------

Step 1) Build 3scale-operator-metadata builder image (once per release)
        $ docker build -t 3scale-operator-metadata-builder .

Step 2) Build/Test 3scale-operator-metadata

        Usage:
                $ docker run --rm -v `pwd`:/ws 3scale-operator-metadata-builder bash -l -c "cd /ws; ./build.sh <rel_tag> 2>&1 | tee output.log"

        Examples:
                ==========
                Build Only
                ==========
                # by default, build "lasttestedrelease" which is v0.5.1 marked as 'Latest_Release' as of Apr-30-2021
                # both the commands below build the "v0.5.1: branch
                $ docker run --rm -v `pwd`:/ws 3scale-operator-metadata-builder bash -l -c "cd /ws; ./build.sh 2>&1 | tee output.log"
                $ docker run --rm -v `pwd`:/ws 3scale-operator-metadata-builder bash -l -c "cd /ws; ./build.sh lasttestedrelease 2>&1 | tee output.log"

                # to build master branch
                $ docker run --rm -v `pwd`:/ws 3scale-operator-metadata-builder bash -l -c "cd /ws; ./build.sh master 2>&1 | tee output.log"

                # build specific branch/release
                $ docker run --rm -v `pwd`:/ws 3scale-operator-metadata-builder bash -l -c "cd /ws; ./build.sh v0.5.1 2>&1 | tee output.log"
