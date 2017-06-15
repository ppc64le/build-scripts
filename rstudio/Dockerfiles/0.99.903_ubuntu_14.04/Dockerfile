## Start with the official rocker image providing 'base R'
FROM ppc64le/ubuntu:trusty

## This handle reaches Carl and Dirk
#MAINTAINER "Carl Boettiger and Dirk Eddelbuettel" rocker-maintainers@eddelbuettel.com

## Add RStudio binaries to PATH
ENV PATH /usr/lib/rstudio-server/bin/:$PATH
ENV DEBIAN_FRONTEND noninteractive

## Download and install RStudio server & dependencies
## Attempts to get detect latest version, otherwise falls back to version given in $VER
## Symlink pandoc, pandoc-citeproc so they are available system-wide
RUN rm -rf /var/lib/apt/lists/ \
  && apt-get -y update \
  && apt-get install -y ant apparmor-utils autotools-dev build-essential \
     ca-certificates cmake fakeroot file g++ git haskell-platform libapparmor1 \
     libapparmor1 libboost-all-dev libbz2-dev libcurl4-openssl-dev libedit2 \
     libicu-dev libpam-dev libpango1.0-dev libssl1.0.0 libssl-dev libxslt1-dev \
     openjdk-7-jdk pandoc pandoc-citeproc pkg-config psmisc python-dev \
     python-setuptools r-base r-base-dev unzip uuid-dev wget zlib1g-dev
RUN sudo apt-get -y upgrade

RUN mkdir rstudio && cd rstudio && \
    wget https://github.com/rstudio/rstudio/tarball/v0.99.903 && \
    tar zxvf ./v0.99.903

#prepare pre-reqs
WORKDIR /rstudio/rstudio-rstudio-0eb2d8e/dependencies/
COPY ./common/* ./common/
RUN chmod a+x ./common/*
RUN ls -al ./common

WORKDIR /rstudio/rstudio-rstudio-0eb2d8e/dependencies/linux
RUN ./install-dependencies-debian --exclude-qt-sdk
RUN mkdir -p /rstudio/rstudio-rstudio-0eb2d8e/build
WORKDIR /rstudio/rstudio-rstudio-0eb2d8e/build

#installation of RSTUDION
RUN cmake .. -DRSTUDIO_TARGET=Server -DCMAKE_BUILD_TYPE=Release && \
    make install

#post installation steps according to INSTALL doc
RUN sudo useradd -r rstudio-server
RUN cp /usr/local/lib/rstudio-server/extras/init.d/debian/rstudio-server /etc/init.d/
RUN sudo update-rc.d rstudio-server defaults
RUN sudo ln -f -s /usr/local/lib/rstudio-server/bin/rstudio-server /usr/sbin/rstudio-server
RUN mkdir -p /var/run/rstudio-server && \
    mkdir -p /var/lock/rstudio-server && \
    mkdir -p /var/log/rstudio-server && \
    mkdir -p /var/lib/rstudio-server

EXPOSE 8787
VOLUME /home/rstudio
#CMD ["/usr/sbin/rstudio-server","start"]
CMD ["/bin/bash"]
#-------------------------------------------------------------
