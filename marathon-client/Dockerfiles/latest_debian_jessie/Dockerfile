FROM ppc64le/openjdk:8-jdk

MAINTAINER "Priya Seth <sethp@us.ibm.com>"

RUN apt-get update -y && \
	apt-get install -y maven && \
	git clone https://github.com/willroden/marathon-client && \
	cd marathon-client && \
	mvn install -DskipTests=true -Dmaven.javadoc.skip=true -B -V && \
	mvn test -B

CMD ["/bin/bash"]
