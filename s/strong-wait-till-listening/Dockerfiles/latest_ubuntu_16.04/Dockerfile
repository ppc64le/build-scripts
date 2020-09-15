FROM node:8
MAINTAINER "Jay Joshi <joshija@us.ibm.com>"
RUN git clone https://github.com/strongloop/strong-wait-till-listening.git && \
    cd strong-wait-till-listening && \
    git checkout v1.0.3 && \
    npm install && \
    npm test 

CMD ["/bin/bash"]
