FROM     ppc64le/openjdk:8
MAINTAINER      "Priya Seth <sethp@us.ibm.com>"

ENV     PATH /usr/lib/rstudio-server/bin/:$PATH
ENV     DEBIAN_FRONTEND noninteractive
ENV 	RStudio_VERSION 1.2.1335
RUN     rm -rf /var/lib/apt/lists/ && \
        apt-get -y update && \
        apt-get install -y ant apparmor-utils autotools-dev build-essential \
            ca-certificates cmake fakeroot file g++ git haskell-platform \
            libapparmor1 libbz2-dev libcurl4-openssl-dev libedit2 libicu-dev \
            libpam-dev libpango1.0-dev libssl-dev libxslt1-dev \
            libboost-all-dev pkg-config psmisc python-dev python-setuptools \
            r-base r-base-dev pandoc pandoc-citeproc unzip uuid-dev wget \
            zlib1g-dev sudo && \
        wget https://github.com/rstudio/rstudio/archive/v${RStduio_VERSION}.tar.gz && \
        tar zxvf v${RStduio_VERSION}.tar.gz && \
        mkdir -p /rstudio-${RStduio_VERSION}/build && \
        cd /rstudio-${RStduio_VERSION}/dependencies/linux && \
        ./install-dependencies-debian --exclude-qt-sdk && \
        cd /rstudio-${RStduio_VERSION}/build && \
        cmake .. -DRSTUDIO_TARGET=Server -DCMAKE_BUILD_TYPE=Release && \
        make install && \
        useradd -r rstudio-server  && \
        cp /usr/local/lib/rstudio-server/extras/init.d/debian/rstudio-server /etc/init.d/ && \
        update-rc.d rstudio-server defaults && \
        ln -f -s /usr/local/lib/rstudio-server/bin/rstudio-server /usr/sbin/rstudio-server && \
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
