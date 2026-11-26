FROM     adoptopenjdk:8-openj9-bionic
MAINTAINER      "Priya Seth <sethp@us.ibm.com>", "Ambuk Kumar <Ambuj.Kumar3@ibm.com>", "Vaishnavi Patil <Vaishnavi.Patil3@ibm.com>"

ENV     PATH /usr/lib/rstudio-server/bin/:$PATH
ENV     DEBIAN_FRONTEND noninteractive
ENV     R_VERSION 4.2.0
ENV     RStudio_VERSION 1.4.1743
ENV     RStudio_BUILD_VERSION 1.4.1743
RUN     rm -rf /var/lib/apt/lists/ && \
        apt-get -y update && \
        apt-get install -y ant apparmor-utils autotools-dev build-essential \
            ca-certificates cmake fakeroot file g++ git haskell-platform \
            libapparmor1 libbz2-dev libcurl4-openssl-dev libedit2 libicu-dev \
            libpam-dev libpango1.0-dev libssl-dev libxslt1-dev tcl8.6-dev tk8.6-dev\
            libboost-all-dev pkg-config psmisc python-dev python-setuptools \
            pandoc pandoc-citeproc unzip uuid-dev wget gfortran libreadline-dev \
            xorg-dev libbz2-ocaml-dev liblzma-dev \
            libghc-pcre-light-dev zlib1g-dev sudo pcre2-utils nodejs
RUN     apt-get install -y libpcre2-dev lsb-release
RUN     wget https://cloud.r-project.org/src/base/R-4/R-${R_VERSION}.tar.gz && \
        tar -xvzf R-${R_VERSION}.tar.gz && cd R-${R_VERSION} && \
        ./configure LIBnn=lib  --enable-R-shlib && \
        make -j4 && make -j4 install
RUN     wget https://github.com/rstudio/rstudio/archive/v${RStudio_VERSION}.tar.gz && \
        tar zxvf v${RStudio_VERSION}.tar.gz && \
        mkdir -p /rstudio-${RStudio_BUILD_VERSION}/build
RUN     apt-get install -y libyaml-cpp-dev libntirpc-dev
RUN     echo "exit 0" > /rstudio-${RStudio_BUILD_VERSION}/dependencies/common/install-crashpad && \
        cd /rstudio-${RStudio_BUILD_VERSION}/src/cpp/r/session && \
        sed -i '70 a extern "C" {\nint Rf_countContexts(int, int);\n}' RSession.cpp && \
        cd /rstudio-${RStudio_BUILD_VERSION}/dependencies/linux && \
        sed -i s/amd64/ppc64el/g ./install-dependencies-bionic && \
        RSTUDIO_DISABLE_CRASHPAD=1 ./install-dependencies-bionic && \
        cd /rstudio-${RStudio_BUILD_VERSION}/build && \
        cmake -j4 .. -DRSTUDIO_TARGET=Server -DCMAKE_BUILD_TYPE=Release
RUN     cd /rstudio-${RStudio_BUILD_VERSION}/dependencies/common && \
        sed -i '42 s/x64/ppc64le/g' ./install-npm-dependencies && \
        cd /rstudio-${RStudio_BUILD_VERSION}/src/gwt && \
        sed -i "152i\         \<jvmarg value='"-Xss16M"'/>" build.xml && \
        cd /rstudio-${RStudio_BUILD_VERSION}/build && \
        make -j4 install && \
        useradd -r rstudio-server  && \
        cp /usr/local/extras/init.d/debian/rstudio-server /etc/init.d/ && \
        update-rc.d rstudio-server defaults && \
        ln -f -s /usr/local/bin/rstudio-server /usr/sbin/rstudio-server && \
        mkdir -p /var/run/rstudio-server && \
        mkdir -p /var/lock/rstudio-server && \
        mkdir -p /var/log/rstudio-server && \
        mkdir -p /var/lib/rstudio-server && \
        set -e && useradd -m -d /home/rstudio -G sudo rstudio && \
        echo rstudio:rstudio | chpasswd && \
        rstudio-server online && cd / && \
        echo -e '#!/bin/bash\ncd /usr/sbin\nrstudio-server start' >> startup.sh && \
        chmod +x startup.sh

EXPOSE 8787
VOLUME /home/rstudio
CMD /startup.sh ; sleep infinity
