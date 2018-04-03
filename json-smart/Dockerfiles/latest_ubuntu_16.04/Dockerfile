FROM openjdk:8
MAINTAINER "Jay Joshi <joshija@us.ibm.com>"

ENV PATH $PATH:$JAVA_HOME/bin
ENV LANG "en_US.UTF-8"
ENV LANGUAGE "en_US:en"
ENV LC_ALL "en_US.UTF-8"

# Install dependencies.
RUN apt-get update -y && \
    apt-get install -y git locales locales-all maven && \
    touch /etc/default/locale && \
    chmod a+w /etc/default/locale && \
    echo "LC_CTYPE=\"en_US.UTF-8\"" >> /etc/default/locale && \
    echo "LC_ALL=\"en_US.UTF-8\"" >> /etc/default/locale && \
    echo "LANG=\"en_US.UTF-8\"" >> /etc/default/locale && \
    locale-gen en_US en_US.UTF-8 && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    git clone https://github.com/netplex/json-smart-v2 && \
    cd json-smart-v2/json-smart && \
    mvn install && \
    mvn test && \
    apt-get purge -y git wget git maven && apt-get autoremove -y
CMD ["/bin/bash"]
