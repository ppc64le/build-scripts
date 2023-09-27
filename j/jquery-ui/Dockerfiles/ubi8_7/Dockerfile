FROM registry.access.redhat.com/ubi8:8.7

MAINTAINER "Stuti Wali <Stuti.Wali@ibm.com>"

ARG PACKAGE_VERSION=1.13.2
ARG NODE_VERSION=12.19.1

ENV SOURCE_DIR=$PWD
ENV PATH=/usr/local/bin:$PATH


RUN yum install -y git fontconfig-devel.ppc64le wget curl libXcomposite libXcursor procps-ng java-11-openjdk-devel alsa-lib atk cups-libs gtk3 libXcursor libXdamage libXext libXi libXrandr libXScrnSaver libXtst pango \
    && wget https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-ppc64le.tar.gz \
    && tar -xzf node-v${NODE_VERSION}-linux-ppc64le.tar.gz

ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-11.0.20.0.8-3.el8.ppc64le
ENV PATH=$JAVA_HOME/bin:$PATH
ENV PATH=$HOME_DIR/node-v${NODE_VERSION}-linux-ppc64le/bin:$PATH

RUN cd $SOURCE_DIR \
    && git clone https://github.com/jquery/jquery-ui \
    && cd jquery-ui && git checkout $PACKAGE_VERSION

RUN npm install

CMD ["bash"]
