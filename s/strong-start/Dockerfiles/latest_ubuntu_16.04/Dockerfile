FROM node:8
MAINTAINER "Yugandha Deshpande <yugandha@us.ibm.com>"

RUN git clone https://github.com/strongloop/strong-start.git  && \
    cd strong-start && \
    git checkout v1.3.4 && \
    npm install && \
    npm test 

ENV PATH $PATH:/strong-start/bin
EXPOSE 8701 3000 3001 3002 3003
CMD ["/bin/bash"]
