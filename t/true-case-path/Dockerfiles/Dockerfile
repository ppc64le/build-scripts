FROM registry.access.redhat.com/ubi8/ubi:8.3

MAINTAINER Siddhesh Ghadi <Siddhesh.Ghadi@ibm.com>

RUN groupadd ubi && useradd -r -g ubi ubi -m  -d "/home/ubi" \
    && dnf install git -y 

USER ubi 
WORKDIR "/home/ubi"

RUN curl https://raw.githubusercontent.com/creationix/nvm/v0.37.2/install.sh | bash \
    && source ~/.bashrc \
    && nvm install 12.22.3                                                                                                                 \
    &&  cd $HOME \
    && git clone https://github.com/Profiscience/true-case-path \
    && echo "cloning complete" \
    && cd ~/true-case-path \
    && npm install . \
    && npm test

CMD ["/bin/bash"]