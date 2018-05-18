FROM node:8
MAINTAINER "Jay Joshi <joshija@us.ibm.com>"
RUN git clone https://github.com/strongloop/generator-loopback.git && \
    cd generator-loopback && \
    git checkout v5.7.1 && \
    npm install && \
    npm test

CMD ["/bin/bash"]
