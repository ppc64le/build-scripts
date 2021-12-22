Build/Test tini
---------------
Tini - A tiny but valid init for containers

All Tini does is spawn a single child (Tini is meant to be run in a container), and wait for it to exit all the
while reaping zombies and performing signal forwarding.


Step 1) Build tini_builder image (once per release)
        $ docker build -t tini_builder .

Step 2) Build/Test tini_builder

        Usage:
                $ docker run --rm -v `pwd`:/ws tini_builder bash -l -c "cd /ws; ./build.sh <rel_tag> 2>&1 | tee output.log"

        Examples:
                =====
                Build
                =====
                # build master by default
                $ docker run --rm -v `pwd`:/ws tini_builder bash -l -c "cd /ws; ./build.sh 2>&1 | tee output.log"

                # build specific branch/release
                $ docker run --rm -v `pwd`:/ws tini_builder bash -l -c "cd /ws; ./build.sh v0.19.0 2>&1 | tee output.log"
