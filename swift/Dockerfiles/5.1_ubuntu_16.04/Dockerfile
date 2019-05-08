FROM ubuntu:16.04
MAINTAINER "Sarvesh Tamba <sarvesh.tamba@ibm.com>"

#Install the pre-requisites
RUN apt-get update -y && \
    apt-get install -y git cmake ninja-build clang python uuid-dev libicu-dev \
    icu-devtools libbsd-dev libedit-dev libxml2-dev libsqlite3-dev swig \
    libpython-dev libncurses5-dev pkg-config libblocksruntime-dev libcurl4-openssl-dev \
    systemtap-sdt-dev tzdata rsync openssh-server libc++-dev libc++abi-dev ocaml \
    autoconf libtool ca-certificates libstdc++-5-dev libobjc-5-dev sphinx-common \
    build-essential g++ re2c libc++1 libc++abi1 libc++-helpers libc++-test \
    libc++abi-test binutils libncurses-dev python-dev sqlite3 python-pexpect gdb

#Copy pre-built 'swift-5.1-branch' based tar file and extract the toolchain.
COPY swift-5.1.tar.gz .
RUN tar -xvzf swift-5.1.tar.gz

# Print Installed Swift Version
RUN swift --version

CMD [ "/bin/bash" ]
