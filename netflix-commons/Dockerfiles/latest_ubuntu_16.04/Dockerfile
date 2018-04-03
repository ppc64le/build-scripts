FROM  openjdk:8
MAINTAINER "Sanchal Singh <sanchals@us.ibm.com>"

RUN apt-get update -y && \
    apt-get install -y git && \
    git clone https://github.com/Netflix/netflix-commons.git && \
    cd netflix-commons && \
    ./gradlew && \
    ./gradlew test && \
    apt-get remove --purge -y git && \
    apt -y autoremove

CMD ["/bin/bash"]
