FROM openjdk:8

MAINTAINER "Priya Seth <sethp@us.ibm.com>"

RUN apt-get update -y && \
	apt-get -y install git maven && \
	git clone https://github.com/kongchen/swagger-maven-plugin && \
	cd swagger-maven-plugin && mvn install && \
	apt-get purge -y git && apt-get autoremove -y

CMD ["/bin/bash"]
