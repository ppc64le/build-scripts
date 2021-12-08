FROM registry.access.redhat.com/ubi8/ubi:8.3 

MAINTAINER Siddhesh Ghadi <Siddhesh.Ghadi@ibm.com>

RUN dnf install git curl  -y \
    && curl https://raw.githubusercontent.com/creationix/nvm/v0.37.2/install.sh | bash \
    && source ~/.bashrc \
    && nvm install 12.22.3                                                                                                                 \
    && cd $HOME \
    && git clone https://github.com/alexreardon/tiny-invariant \
    && echo "cloning complete" \
    && cd ~/tiny-invariant \
    && npm install yarn && npm install  \
    && npm test 

CMD ["/bin/bash"]