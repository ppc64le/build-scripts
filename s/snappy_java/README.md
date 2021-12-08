Build/ Test snappy_java
-----------------------

Snappy-Java: It is a Java port of the snappy, a fast C++ compresser/decompresser developed by Google.

Step 1) Build the container image for snappy_java ( once per release )
	$ docker build --build-arg USERNAME="rhel_subscription_id" --build-arg PASSWORD="rhel_subscription_password" -t snappy_java:ibm .

Step 2) Build/ Test snappy_java container image

        Usage:
                $ docker run --rm -v `pwd`:/ws snappy_java:ibm bash -l -c "cd /ws; ./build.sh <rel_tag> 2>&1 | tee output.log"

        Examples:
                ==========
                Build Only
                ==========
                # build master by default or pass desired release_tag.
                $ docker run --rm -v `pwd`:/ws snappy_java:ibm bash -l -c "cd /ws; ./build.sh 2>&1 | tee output.log"

                # build specific branch/release.
                $ docker run --rm -v `pwd`:/ws snappy_java:ibm bash -l -c "cd /ws; ./build.sh 1.1.8.1 2>&1 | tee output.log"
