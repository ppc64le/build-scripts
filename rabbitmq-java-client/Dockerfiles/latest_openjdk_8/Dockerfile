FROM openjdk:8
MAINTAINER "Atul Sowani <sowania@us.ibm.com>"

ENV JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el
ENV PATH=$JAVA_HOME/bin:$PATH
ENV JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF-8"
ENV DEBIAN_FRONTEND="noninteractive"

RUN apt-get update -y && \
    apt-get install -y software-properties-common maven git zip \
        python python-simplejson openssl wget ssl-cert rsync \
        xsltproc unzip make libncurses5-dev libssl-dev locales \
        libncurses5 libncurses5-dev unixodbc unixodbc-dev gcc && \
        sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
        locale-gen && \
    cd && \
        wget http://erlang.org/download/otp_src_20.0.tar.gz && \
        tar xvzf otp_src_20.0.tar.gz && cd otp_src_20.0 && \
        rm -rf ../otp_src_20.0.tar.gz && \
        ./configure && make && make install && \
        cd .. && rm -rf otp_src_20.0 && \
    cd && \
        git clone https://github.com/elixir-lang/elixir.git && \
        cd elixir && git checkout v1.7.3 && \
        make clean test && make install && \
        cd .. && rm -rf elixir && \
    cd && \
        git clone --recursive https://github.com/rabbitmq/rabbitmq-public-umbrella.git && \
        cd rabbitmq-public-umbrella && \
        make co && cd deps/rabbitmq_java_client && make && mvn verify && \
        apt-get remove --purge -y software-properties-common maven git wget \
        unzip make xsltproc libncurses5-dev libssl-dev libncurses5-dev zip \
        unixodbc-dev gcc && apt-get autoremove -y

CMD ["/bin/bash"]
