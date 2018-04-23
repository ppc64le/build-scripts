FROM ppc64le/ubuntu:16.04
MAINTAINER "Jay Joshi<joshija@us.ibm.com>"

RUN apt-get update -y && \
    apt-get install -y build-essential wget npm zip git && \

    # Build and install node.
    wget https://nodejs.org/dist/v4.7.0/node-v4.7.0.tar.gz && \
    tar -xzf node-v4.7.0.tar.gz  && \
    cd node-v4.7.0 && \
    ./configure && \
    make && \
    make install && \
    cd .. && rm -rf node-v4.7.0 node-v4.7.0.tar.gz && \

    # Clone and build d3.
    git clone https://github.com/mbostock/d3.git && \
    cd d3 && \
    npm install && \
    npm test && \
    apt-get purge -y git build-essential wget zip && \
    apt-get autoremove -y

CMD ["/bin/bash"]
