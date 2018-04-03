FROM  openjdk:8
MAINTAINER "Sanchal Singh <sanchals@us.ibm.com>"

RUN     apt-get update -y && \
        apt-get install -y apt-transport-https && \
        rm -rf /etc/apt/sources.list.d/sbt.list && \
        touch /etc/apt/sources.list.d/sbt.list && \
        echo "deb https://dl.bintray.com/sbt/debian /" | tee -a /etc/apt/sources.list.d/sbt.list && \
        apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2EE0EA64E40A89B84B2DF73499E82A75642AC823 && \
        apt-get update -y && \
        apt-get install -y sbt build-essential dirmngr git && \
        git clone https://github.com/codingwell/scala-guice.git && \
        cd scala-guice && \
        git checkout -qf 52fb146e73b8be0075f994ace8a6af6928ff00ec && \
        sbt compile && \
        sbt test && \
        apt-get remove --purge -y git sbt dirmngr apt-transport-https && \
        apt -y autoremove

CMD ["/bin/bash"]
