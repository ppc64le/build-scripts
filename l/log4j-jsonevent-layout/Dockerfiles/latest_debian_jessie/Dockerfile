FROM ppc64le/openjdk:8-jdk

MAINTAINER "Priya Seth <sethp@us.ibm.com>"

RUN apt-get update -y && \
	apt-get install -y git maven && \
	git clone https://github.com/logstash/log4j-jsonevent-layout && \
	cd log4j-jsonevent-layout && \
	mvn install

CMD ["/bin/bash"]
