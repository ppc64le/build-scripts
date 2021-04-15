ActiveMQ

Building and saving Apache ActiveMQ

Step 1) Build the ActiveMQ builder image (once per release)
	$ docker build -t activemq_builder .
Step 2) Compile and package ActiveMQ binary
	$ docker run --rm -v `pwd`:/ws activemq_builder bash -l -c "cd /ws; ./build.sh" 

