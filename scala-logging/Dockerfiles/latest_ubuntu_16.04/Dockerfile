FROM  openjdk:8
MAINTAINER "Sanchal Singh <sanchals@us.ibm.com>"

RUN     apt-get update -y  && \
        apt-get install -y apt-transport-https && \
        rm -rf /etc/apt/sources.list.d/sbt.list && \
        touch /etc/apt/sources.list.d/sbt.list && \
        echo "deb https://dl.bintray.com/sbt/debian /" | tee -a /etc/apt/sources.list.d/sbt.list && \
        apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 642AC823 && \
        apt-get update -y && \
        apt-get install -y build-essential dirmngr sbt git && \
        git clone https://github.com/typesafehub/scala-logging && \
        cd scala-logging && \
        sbt compile && \
        sbt test && \
        apt-get remove --purge -y git apt-transport-https dirmngr sbt && \
        apt -y autoremove

CMD ["/bin/bash"]
