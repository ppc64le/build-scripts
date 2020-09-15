FROM ppc64le/openjdk:8-jdk

MAINTAINER "Priya Seth <sethp@us.ibm.com>"

RUN apt-get update -y && \
	apt-get install -y maven && \
	git clone https://github.com/dropwizard/metrics.git && \
	cd metrics && \
	git checkout -qf e61022231d2e1ab4f4998a9d7d28eb29de335dec && \
	mvn verify

CMD ["/bin/bash"]
