FROM ppc64le/openjdk:8-jdk

MAINTAINER "Priya Seth <sethp@us.ibm.com>"

RUN apt-get update -y && apt-get install -y ant && \
	git clone https://github.com/mimno/Mallet.git && \
	cd Mallet && ant

CMD ["/bin/bash"]
