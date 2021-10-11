Build/Test 3scale_zync
----------------------

zync takes 3scale data and pushes it somewhere else, reliably. Offers only one directional sync (from 3scale to other systems).

Step 1) Build 3scale_zync builder image (once per release)
        $ docker build -t 3scale_zync_builder .

Step 2) Build and Test 3scale_zync.

        Usage:
                $ docker run --rm -v `pwd`:/ws 3scale_zync_builder bash -l -c "cd /ws; ./build.sh <rel_tag> <runtest> 2>&1 | tee output.log"

        Examples:
                ==========
                Build Only
                ==========
                # build master by default or pass "lasttestedrelease". No tests
                $ docker run --rm -v `pwd`:/ws 3scale_zync_builder bash -l -c "cd /ws; ./build.sh 2>&1 | tee output.log"
                $ docker run --rm -v `pwd`:/ws 3scale_zync_builder bash -l -c "cd /ws; ./build.sh lasttestedrelease 2>&1 | tee output.log"

                # build specific branch/release. No tests
                $ docker run --rm -v `pwd`:/ws 3scale_zync_builder bash -l -c "cd /ws; ./build.sh 3scale-2.10.0-GA 2>&1 | tee output.log"


                ===================
                Build and Run Tests
                ===================
                # build last tested release and run test
                $ docker run --rm -v `pwd`:/ws 3scale_zync_builder bash -l -c "cd /ws; ./build.sh lasttestedrelease runtest 2>&1 | tee output.log"

                # build release "3scale-2.10.0-GA" and run tests
                $ docker run --rm -v `pwd`:/ws 3scale_zync_builder bash -l -c "cd /ws; ./build.sh 3scale-2.10.0-GA runtest 2>&1 | tee output.log"

