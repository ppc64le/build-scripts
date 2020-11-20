FROM ppc64le/openjdk:8-jdk

MAINTAINER "Priya Seth <sethp@us.ibm.com>"

RUN apt-get update -y && \
	apt-get -y install git maven && \
	git clone https://github.com/swagger-api/swagger-core && \
	cd swagger-core && mvn install && \
	apt-get purge -y git && apt-get autoremove -y

CMD ["/bin/bash"]
