Build/Test apisonator
----------------------

This is the Red Hat 3scale API Management backend.

Step 1) Build apisonator builder image (once per release)
        $ ./build.sh 2>&1 | tee output.log

Step 2) Build and Test apisonator.

        Usage:
                $ ./build.sh <rel_tag> <runtest> 2>&1 | tee output.log"

        Examples:
                ==========
                Build Only
                ==========
                # build master by default or pass "lasttestedrelease". No tests
                $ ./build.sh 2>&1 | tee output.log
                $ ./build.sh lasttestedrelease 2>&1 | tee output.log

                # build specific branch/release. No tests
                $ ./build.sh 3scale-2.11-stable 2>&1 | tee output.log


                ===================
                Build and Run Tests
                ===================
                # build last tested release and run test
                $ ./build.sh lasttestedrelease runtest 2>&1 | tee output.log

                # build release "3scale-2.11-stable" and run tests
                $ ./build.sh 3scale-2.11-stable runtest 2>&1 | tee output.log

